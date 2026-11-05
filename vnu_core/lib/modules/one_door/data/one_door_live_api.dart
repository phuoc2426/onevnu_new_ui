import 'package:dio/dio.dart';

/// This endpoint is NOT included in the older One Door Swagger. Its wire
/// contract must be confirmed against the actual /auth/onevnu deployment.
enum OneDoorTokenPlacement { authorizationHeader, jsonBody }

class OneDoorSession {
  const OneDoorSession({required this.accessToken, this.expiresAtUtc});
  final String accessToken;
  final DateTime? expiresAtUtc;

  bool get isValid => accessToken.trim().isNotEmpty &&
      (expiresAtUtc == null || expiresAtUtc!.isAfter(DateTime.now().toUtc()));
  bool get expiresSoon => expiresAtUtc != null &&
      !expiresAtUtc!.isAfter(DateTime.now().toUtc().add(const Duration(seconds: 45)));
}

class OneDoorOneVnuAuthApi {
  OneDoorOneVnuAuthApi({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: 'https://motcua-vnu.digitaledu.vn/mc-api',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));
  final Dio _dio;

  Future<OneDoorSession> exchange({
    required String oneVnuJwt,
    OneDoorTokenPlacement placement = OneDoorTokenPlacement.jsonBody,
  }) async {
    final token = oneVnuJwt.trim();
    if (token.isEmpty) throw StateError('Missing ONEVNU login token');
    // No automatic header-to-body fallback: that could leak a JWT to an
    // unexpected contract. Header placement is the integration assumption.
    final response = await _dio.post<dynamic>('/api/v1/auth/onevnu',
      data: placement == OneDoorTokenPlacement.jsonBody
          ? <String, dynamic>{'token': token} : null,
      options: Options(headers: placement == OneDoorTokenPlacement.authorizationHeader
          ? <String, String>{'Authorization': 'Bearer $token'}
          : const <String, String>{'Content-Type': 'application/json'}),
    );
    final data = _oneDoorMap(response.data);
    final access = (data['accessToken'] ?? data['access_token'] ??
        data['token'] ?? data['jwt'])?.toString().trim() ?? '';
    if (access.isEmpty) {
      throw const FormatException('One Door did not return an access token');
    }
    final rawExpiry = (data['expiresAtUtc'] ?? data['expiresAt'])?.toString();
    DateTime? expiry = rawExpiry == null ? null : DateTime.tryParse(rawExpiry)?.toUtc();
    final seconds = int.tryParse('${data['expiresIn'] ?? data['expires_in'] ?? ''}');
    if (expiry == null && seconds != null && seconds > 0) {
      expiry = DateTime.now().toUtc().add(Duration(seconds: seconds));
    }
    final session = OneDoorSession(accessToken: access, expiresAtUtc: expiry);
    if (!session.isValid) throw const FormatException('One Door token is expired');
    return session;
  }
}

class OneDoorTemplateFile {
  const OneDoorTemplateFile({required this.bytes, required this.extension});
  final List<int> bytes;
  final String extension;
}

/// Uses ONLY the One Door token. Safe GET requests may exchange a new token
/// once on HTTP 401. Never automatically replay a POST with file attachments.
class OneDoorLiveApi {
  OneDoorLiveApi(OneDoorSession session, {
    Dio? dio,
    Future<OneDoorSession> Function()? refreshSession,
  }) : _session = session,
       _refreshSession = refreshSession,
       _dio = dio ?? Dio(BaseOptions(
         baseUrl: 'https://motcua-vnu.digitaledu.vn/mc-api',
         connectTimeout: const Duration(seconds: 20),
         receiveTimeout: const Duration(seconds: 20),
       ));

  OneDoorSession _session;
  final Dio _dio;
  final Future<OneDoorSession> Function()? _refreshSession;
  Future<OneDoorSession>? _refreshInFlight;
  Options get _options => Options(headers: <String, String>{
    'Authorization': 'Bearer ${_session.accessToken}',
  });

  Future<void> _refresh() async {
    final callback = _refreshSession;
    if (callback == null) throw StateError('One Door session cannot be refreshed');
    _refreshInFlight ??= callback();
    try {
      final next = await _refreshInFlight!;
      if (!next.isValid) throw StateError('Invalid refreshed One Door session');
      _session = next;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    if (_session.expiresSoon) await _refresh();
    try {
      return (await _dio.get<dynamic>(path,
        queryParameters: query, options: _options)).data;
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || _refreshSession == null) rethrow;
      await _refresh();
      return (await _dio.get<dynamic>(path,
        queryParameters: query, options: _options)).data;
    }
  }

  Future<dynamic> _post(String path, {dynamic body}) async {
    // Refresh before the write if the expiry is known. For an unexpected
    // 401 during POST, surface the error; never auto-resubmit a write.
    if (_session.expiresSoon) await _refresh();
    try {
      return (await _dio.post<dynamic>(path,
        data: body, options: _options)).data;
    } on DioException catch(error) {
      if (error.response?.statusCode == 401 && _refreshSession != null) {
        // Prepare a fresh session for a future user-initiated attempt.
        // Never re-send the failed POST automatically.
        await _refresh();
      }
      rethrow;
    }
  }

  Future<dynamic> currentUser() => _get('/api/v1/auth/me');

  /// Source-of-truth catalog: daiHocQuocGia, truongs, thuTucDaiHocQuocGia.
  /// Public One Door API; uses the same One Door session and GET retry policy.
  Future<dynamic> procedureCatalog() =>
    _get('/api/v1/public/thu-tuc/theo-cap');

  /// Logged-in student's program memberships: tenDonVi + dangChon.
  /// The One Door contract exposes names, not a One Door unit ID.
  Future<dynamic> myAcademicMajors() => _get('/api/v1/nganh-cua-toi');

  Future<dynamic> listProcedures({int page = 1, int pageSize = 30,
    String? search, int? unitId, int? unitLevel, String? audienceId}) =>
    _get('/api/v1/public/thu-tuc', query: <String, dynamic>{
      'PageNumber': page, 'PageSize': pageSize,
      if (search != null && search.trim().isNotEmpty) 'Keyword': search.trim(),
      if (unitId != null) 'IdDV': unitId,
      if (unitLevel != null) 'CapDonVi': unitLevel,
      if (audienceId != null && audienceId.trim().isNotEmpty)
        'IdDoiTuong': audienceId.trim(),
    });

  Future<dynamic> procedure(String id) =>
    _get('/api/v1/public/thu-tuc/${Uri.encodeComponent(id)}');

  Future<dynamic> conditions(String id) =>
    _get('/api/v1/ho-so/dieu-kien-nop/${Uri.encodeComponent(id)}');

  /// Both official raw sample and the authenticated server-filled document
  /// are declared GET endpoints in the supplied OpenAPI. We never guess the
  /// filled file's extension or edit its bytes in place.
  Future<OneDoorTemplateFile> paperTemplate(String paperId,
      {bool prefilled = false}) async {
    if (paperId.trim().isEmpty) throw ArgumentError('idGiayTo is required');
    if (_session.expiresSoon) await _refresh();
    final path = '/api/v1/files/giay-to-mau/${Uri.encodeComponent(paperId)}'
        '${prefilled ? '/da-dien' : ''}';
    Future<Response<List<int>>> download() => _dio.get<List<int>>(path,
      options: Options(responseType: ResponseType.bytes,
        headers: <String, String>{'Authorization': 'Bearer ${_session.accessToken}'}));
    late Response<List<int>> response;
    try {
      response = await download();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || _refreshSession == null) rethrow;
      await _refresh();
      response = await download();
    }
    final bytes = response.data ?? const <int>[];
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Tệp không tồn tại hoặc lớn hơn 10 MB.');
    }
    final mime = (response.headers.value('content-type') ?? '').toLowerCase();
    if (mime.contains('json') || mime.contains('text/html')) {
      throw const FormatException('API không trả về tệp hợp lệ.');
    }
    final isPdf = bytes.length > 4 && bytes[0] == 0x25 &&
        bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
    final isPng = bytes.length > 7 && bytes[0] == 0x89 && bytes[1] == 0x50;
    final isJpeg = bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    final isOle = bytes.length > 4 && bytes[0] == 0xD0 && bytes[1] == 0xCF;
    final disposition = (response.headers.value('content-disposition') ?? '')
        .toLowerCase();
    final isSheet = mime.contains('spreadsheet') || mime.contains('excel') ||
        disposition.contains('.xlsx') || disposition.contains('.xls');
    final ext = isPdf ? 'pdf' : isPng ? 'png' : isJpeg ? 'jpg' :
      isZip ? (isSheet ? 'xlsx' : 'docx') :
      isOle ? (isSheet ? 'xls' : 'doc') : '';
    if (ext.isEmpty) {
      throw const FormatException('Định dạng tệp mẫu chưa được hỗ trợ.');
    }
    return OneDoorTemplateFile(bytes: bytes, extension: ext);
  }

  Future<dynamic> myRecords({int page = 1, int pageSize = 30}) =>
    _get('/api/v1/ho-so/cua-toi', query: <String, dynamic>{
      'PageNumber': page, 'PageSize': pageSize,
    });

  Future<dynamic> myRecordSummary() => _get('/api/v1/ho-so/cua-toi/tong-hop');

  Future<dynamic> record(String id) =>
    _get('/api/v1/ho-so/${Uri.encodeComponent(id)}');

  Future<dynamic> lookup(String type) {
    const allowed = <String>{'doi-tuong', 'linh-vuc',
        'hinh-thuc-nhan-ket-qua'};
    if (!allowed.contains(type)) throw ArgumentError.value(type, 'type');
    return _get('/api/v1/lookups/$type');
  }

  /// Files are named by their idGiayTo, NOT a generic 'files' field.
  /// The Swagger specifies integer IdLyDo, mandatory string delivery ID,
  /// and mandatory positive integer SoLuongBan.
  Future<dynamic> submit({required String procedureId, required String request,
      required Map<String, String> filesByPaperId, int? reasonId,
      required String deliveryMethodId, required int quantity}) async {
    if (procedureId.trim().isEmpty) throw ArgumentError('IdThuTuc is required');
    if (deliveryMethodId.trim().isEmpty) {
      throw ArgumentError('IdHinhThucNhanKetQua is required');
    }
    if (quantity < 1) throw ArgumentError('SoLuongBan must be positive');
    final data = FormData.fromMap(<String, dynamic>{
      'IdThuTuc': procedureId,
      'YeuCau': request,
      'IdHinhThucNhanKetQua': deliveryMethodId,
      'SoLuongBan': quantity,
      if (reasonId != null) 'IdLyDo': reasonId,
    });
    await _attach(data, filesByPaperId);
    return _post('/api/v1/ho-so', body: data);
  }

  Future<dynamic> supplement(String registrationId, {
      required String note, required Map<String, String> filesByPaperId}) async {
    final data = FormData.fromMap(<String, dynamic>{'GhiChu': note});
    await _attach(data, filesByPaperId);
    return _post('/api/v1/ho-so/${Uri.encodeComponent(registrationId)}/bo-sung',
      body: data);
  }

  Future<dynamic> cancel(String registrationId) =>
    _post('/api/v1/ho-so/${Uri.encodeComponent(registrationId)}/huy');

  Future<List<int>> resultFile(String registrationId) async {
    if (_session.expiresSoon) await _refresh();
    final path = '/api/v1/ho-so/${Uri.encodeComponent(registrationId)}/ket-qua/file';
    Future<Response<List<int>>> download() => _dio.get<List<int>>(path,
      options: Options(responseType: ResponseType.bytes,
        headers: <String, String>{'Authorization': 'Bearer ${_session.accessToken}'}));
    try {
      return (await download()).data ?? <int>[];
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || _refreshSession == null) rethrow;
      await _refresh();
      return (await download()).data ?? <int>[];
    }
  }

  Future<void> _attach(FormData data, Map<String, String> filesByPaperId) async {
    for (final entry in filesByPaperId.entries) {
      final id = entry.key.trim();
      if (id.isEmpty) throw ArgumentError('idGiayTo is required');
      final path = entry.value.trim();
      if (path.isEmpty) continue;
      data.files.add(MapEntry<String, MultipartFile>(id,
        await MultipartFile.fromFile(path)));
    }
  }
}

Map<String, dynamic> _oneDoorMap(dynamic raw) {
  if (raw is! Map) throw const FormatException('Invalid One Door response');
  var data = Map<String, dynamic>.from(raw);
  for (var i = 0; i < 2; i++) {
    final nested = data['data'] ?? data['result'];
    if (nested is! Map) break;
    data = Map<String, dynamic>.from(nested);
  }
  return data;
}
