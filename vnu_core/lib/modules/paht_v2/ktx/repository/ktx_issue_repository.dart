import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/paht_v2/ktx/models/ktx_issue_models.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/services/services_url.dart';

/// API client cho subsystem Phản ánh hiện trường KTX.
///
/// Production contract đã kiểm chứng bằng curl ngày 30/08/2026:
/// - Tất cả API Issue vẫn gửi Authorization: Bearer <ONEVNU_ACCESS_TOKEN>.
/// - GET /issues cần student_code hoặc identity_no để backend resolve sinh viên.
/// - GET /issues/{id} cũng cần student_code hoặc identity_no.
/// - POST /issues/{id}/comments cần comment và nên gửi kèm định danh.
/// - room_id/dormitory_id KHÔNG dùng để xác thực quyền xem issue.
/// - Khi KTX trả 401, thử refresh access token ONEVNU đúng 1 lần rồi retry.
class KtxIssueRepository {
  KtxIssueRepository._internal();

  static final KtxIssueRepository _singleton =
      KtxIssueRepository._internal();

  factory KtxIssueRepository() => _singleton;

  static const int maxImageBytes = 5 * 1024 * 1024;

  Dio? _dio;
  String _baseUrl = '';
  _KtxIssueResidenceContext? _residenceContext;


  /// KTX issue is available when the current student already has a real KTX
  /// residence. The documented /dormitory/me contract does NOT expose room_id
  /// in accommodations and POST /issues makes room_id optional, so eligibility
  /// must never depend on resolving room_id/dormitory_id first.
  Future<bool> isKtxResidentEligible() async {
    final String studentCode = _studentCode();
    final String identityNo = _identityNo();

    final List<Map<String, dynamic>> queries = <Map<String, dynamic>>[];
    if (studentCode.isNotEmpty) {
      queries.add(<String, dynamic>{'student_code': studentCode});
    }
    if (identityNo.isNotEmpty) {
      queries.add(<String, dynamic>{'identity_no': identityNo});
    }
    if (studentCode.isNotEmpty && identityNo.isNotEmpty) {
      queries.add(<String, dynamic>{
        'student_code': studentCode,
        'identity_no': identityNo,
      });
    }

    for (final Map<String, dynamic> query in queries) {
      try {
        final Response<Map<String, dynamic>> response = await _authorizedGet(
          'dormitory/me',
          queryParameters: query,
        );
        if (_hasAssignedAccommodation(response.data)) {
          _captureResidenceContext(response.data, source: 'dormitory/me');
          logInfo(
            '[KTX_ISSUE_ELIGIBILITY] eligible=true source=dormitory/me '
            'query=${query.keys.join(',')}',
          );
          return true;
        }
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        if (statusCode != 404 && statusCode != 422) {
          logWarning(
            '[KTX_ISSUE_ELIGIBILITY] dormitory/me failed '
            'status=$statusCode query=${query.keys.join(',')}',
          );
        }
      } catch (error) {
        logWarning('[KTX_ISSUE_ELIGIBILITY] dormitory/me failed: $error');
      }
    }

    // student.show is richer and also documents accommodations[].status and
    // assignedRoom. Use only as a compatibility fallback if /dormitory/me did
    // not establish eligibility.
    if (studentCode.isNotEmpty) {
      try {
        final String encoded = Uri.encodeComponent(studentCode);
        final Response<Map<String, dynamic>> response =
            await _authorizedGet('students/$encoded');
        if (_hasAssignedAccommodation(response.data)) {
          _captureResidenceContext(response.data, source: 'student.show');
          logInfo('[KTX_ISSUE_ELIGIBILITY] eligible=true source=student.show');
          return true;
        }
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        if (statusCode != 404 && statusCode != 422) {
          logWarning(
            '[KTX_ISSUE_ELIGIBILITY] student.show failed status=$statusCode',
          );
        }
      } catch (error) {
        logWarning('[KTX_ISSUE_ELIGIBILITY] student.show failed: $error');
      }
    }

    logInfo('[KTX_ISSUE_ELIGIBILITY] eligible=false');
    return false;
  }

  bool _hasAssignedAccommodation(Map<String, dynamic>? body) {
    if (body == null) return false;
    final dynamic rawData = body['data'] ?? body;
    if (rawData is! Map) return false;

    final dynamic rawStudent = rawData['student'];
    if (rawStudent is Map) {
      final int? studentRoomId = int.tryParse(
        (rawStudent['room_id'] ?? rawStudent['roomId'] ?? '').toString(),
      );
      if (studentRoomId != null && studentRoomId > 0) return true;
    }

    final dynamic rawItems = rawData['accommodations'];
    if (rawItems is! List) return false;

    for (final dynamic raw in rawItems) {
      if (raw is! Map) continue;
      final String status = (raw['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase()
          .replaceAll('-', '_');
      final String statusLabel = (raw['statusLabel'] ?? raw['status_label'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final String assignedRoom =
          (raw['assignedRoom'] ?? raw['assigned_room'] ?? '').toString().trim();
      final int? roomId = int.tryParse(
        (raw['room_id'] ?? raw['roomId'] ?? '').toString(),
      );

      if (roomId != null && roomId > 0) return true;
      if (status == 'assigned' || status == 'active' || status == 'staying') {
        return true;
      }
      if (statusLabel.contains('gán phòng') ||
          statusLabel.contains('đang ở') ||
          statusLabel.contains('đang lưu trú')) {
        return true;
      }
      // In the documented summary assignedRoom is the only room signal. When
      // backend has already populated it, the student has been assigned a room.
      if (assignedRoom.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<KtxIssueMeta> getMeta() async {
    try {
      final Response<Map<String, dynamic>> response =
          await _authorizedGet('issues/meta');
      return KtxIssueMeta.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Danh sách phản ánh của sinh viên.
  ///
  /// Backend production hiện tại không tự resolve sinh viên chỉ từ Bearer
  /// token. Ít nhất student_code hoặc identity_no phải được gửi ở query.
  Future<KtxIssuePage> getIssues({String? nextPageUrl}) async {
    final Map<String, dynamic> query = <String, dynamic>{
      ...?_queryFromPaginatorUrl(nextPageUrl),
      ..._studentIdentityQuery(),
    };

    logInfo(
      '[KTX_ISSUE_LIST_REQUEST] '
      'page=${query['page'] ?? 1} '
      'query=${_safeQueryLog(query)}',
    );

    try {
      final Response<Map<String, dynamic>> response = await _authorizedGet(
        'issues',
        queryParameters: query,
      );

      final Map<String, dynamic> body =
          response.data ?? <String, dynamic>{};
      final KtxIssuePage page = KtxIssuePage.fromJson(body);

      logInfo(
        '[KTX_ISSUE_LIST_RESPONSE] status=${response.statusCode} '
        'items=${page.items.length} total=${page.total} '
        'currentPage=${page.currentPage} lastPage=${page.lastPage} '
        'next=${page.nextPageUrl != null}',
      );

      return page;
    } on DioException catch (error) {
      logWarning(
        '[KTX_ISSUE_LIST_ERROR] status=${error.response?.statusCode} '
        'query=${_safeQueryLog(query)} '
        'response=${_shortLog(error.response?.data)}',
      );
      throw _mapDioException(error);
    }
  }

  /// Chi tiết phản ánh. Production yêu cầu cùng định danh sinh viên như list.
  Future<KtxIssue> getIssue(int id) async {
    final Map<String, dynamic> query = _studentIdentityQuery();

    logInfo(
      '[KTX_ISSUE_DETAIL_REQUEST] issueId=$id '
      'query=${_safeQueryLog(query)}',
    );

    try {
      final Response<Map<String, dynamic>> response = await _authorizedGet(
        'issues/$id',
        queryParameters: query,
      );

      final dynamic rawData = response.data?['data'];
      logInfo(
        '[KTX_ISSUE_DETAIL_RESPONSE] issueId=$id '
        'status=${response.statusCode} data=${_shortLog(rawData)}',
      );
      if (rawData is! Map) {
        throw const KtxIssueApiException(
          'Dữ liệu chi tiết phản ánh KTX không hợp lệ.',
        );
      }

      return KtxIssue.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (error) {
      logWarning(
        '[KTX_ISSUE_DETAIL_ERROR] issueId=$id '
        'status=${error.response?.statusCode} '
        'query=${_safeQueryLog(query)} '
        'response=${_shortLog(error.response?.data)}',
      );
      throw _mapDioException(error);
    }
  }

  Future<KtxIssue> createIssue({
    required String title,
    required String description,
    required int type,
    int? priority,
    int? roomId,
    double? latitude,
    double? longitude,
    String? address,
    String? mapUrl,
    List<XFile> images = const <XFile>[],
  }) async {
    final _KtxIssueResidenceContext context =
        await _resolveResidenceContextIfNeeded();
    final int? effectiveRoomId = roomId ?? context.roomId;
    final FormData formData = FormData();

    // Production resolve sinh viên bằng student_code/identity_no; gửi cả hai
    // khi có để POST /issues nhất quán với list/detail/comment.
    _addField(formData, 'student_code', _studentCode());
    _addField(formData, 'identity_no', _identityNo());
    _addField(formData, 'title', title.trim());
    _addField(formData, 'description', description.trim());
    _addField(formData, 'type', type);
    _addField(formData, 'priority', priority);
    _addField(formData, 'room_id', effectiveRoomId);
    _addField(formData, 'latitude', latitude);
    _addField(formData, 'longitude', longitude);
    _addField(formData, 'address', address?.trim());
    _addField(formData, 'map_url', mapUrl?.trim());

    for (final XFile image in images) {
      final int length = await image.length();
      if (length > maxImageBytes) {
        throw KtxIssueApiException(
          'Ảnh "${image.name}" vượt quá 5 MB.',
        );
      }

      formData.files.add(
        MapEntry<String, MultipartFile>(
          'images[]',
          await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        ),
      );
    }

    logInfo(
      '[KTX_ISSUE_CREATE] '
      'type=$type priority=$priority roomId=$effectiveRoomId '
      'dormitoryId=${context.dormitoryId} contextSource=${context.source} '
      'studentCode=${_studentCode().isEmpty ? '<empty>' : _studentCode()} '
      'identityNo=${_maskedIdentity(_identityNo())} '
      'hasLocation=${latitude != null && longitude != null} '
      'images=${images.length}',
    );

    try {
      final Response<Map<String, dynamic>> response =
          await _authorizedPost(
        'issues',
        data: formData,
        multipart: true,
      );

      final dynamic rawData = response.data?['data'];
      if (rawData is! Map) {
        throw const KtxIssueApiException(
          'KTX đã nhận phản ánh nhưng response không có dữ liệu chi tiết.',
        );
      }

      return KtxIssue.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<KtxIssueComment> sendComment({
    required int issueId,
    required String comment,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      ..._studentIdentityQuery(),
      'comment': comment.trim(),
    };

    logInfo(
      '[KTX_ISSUE_COMMENT_REQUEST] issueId=$issueId '
      'identity=${_safeQueryLog(_studentIdentityQuery())} '
      'commentLength=${comment.trim().length}',
    );

    try {
      final Response<Map<String, dynamic>> response = await _authorizedPost(
        'issues/$issueId/comments',
        data: body,
      );

      // Production trả object vừa tạo: id, issue_id, student_id, comment,
      // created_at, updated_at. Parser KtxIssueComment hỗ trợ student_id để
      // xác định đây là tin nhắn của sinh viên.
      final dynamic rawData = response.data?['data'];
      logInfo(
        '[KTX_ISSUE_COMMENT_RESPONSE] issueId=$issueId '
        'status=${response.statusCode} data=${_shortLog(rawData)}',
      );
      if (rawData is! Map) {
        throw const KtxIssueApiException(
          'Không đọc được tin nhắn vừa gửi từ KTX.',
        );
      }

      return KtxIssueComment.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on DioException catch (error) {
      logWarning(
        '[KTX_ISSUE_COMMENT_ERROR] issueId=$issueId '
        'status=${error.response?.statusCode} '
        'response=${_shortLog(error.response?.data)}',
      );
      throw _mapDioException(error);
    }
  }

  void _captureResidenceContext(
    Map<String, dynamic>? body, {
    required String source,
  }) {
    if (body == null) return;
    final dynamic rawData = body['data'] ?? body;
    if (rawData is! Map) return;

    int? dormitoryId;
    int? roomId;
    String assignedRoom = '';

    void inspectAccommodation(dynamic raw) {
      if (raw is! Map) return;

      final int? candidateDormitoryId = _positiveInt(
        raw['dormitory_id'] ??
            raw['dormitoryId'] ??
            (raw['dormitory'] is Map ? raw['dormitory']['id'] : null),
      );
      final int? candidateRoomId = _positiveInt(
        raw['room_id'] ??
            raw['roomId'] ??
            (raw['room'] is Map ? raw['room']['id'] : null),
      );
      final String candidateRoom = (
        raw['assignedRoom'] ??
        raw['assigned_room'] ??
        (raw['room'] is Map
            ? (raw['room']['room_number'] ?? raw['room']['roomNumber'])
            : null) ??
        ''
      ).toString().trim();

      if (candidateDormitoryId != null) {
        dormitoryId ??= candidateDormitoryId;
      }
      if (candidateRoomId != null) {
        roomId ??= candidateRoomId;
      }
      if (candidateRoom.isNotEmpty && assignedRoom.isEmpty) {
        assignedRoom = candidateRoom;
      }
    }

    final dynamic rawStudent = rawData['student'];
    if (rawStudent is Map) {
      dormitoryId = _positiveInt(
        rawStudent['dormitory_id'] ?? rawStudent['dormitoryId'],
      );
      roomId = _positiveInt(rawStudent['room_id'] ?? rawStudent['roomId']);

      // /dormitory/me production trả full accommodation nằm bên trong
      // data.student.accommodations, đây là nguồn chính xác nhất cho room_id
      // và dormitory_id (ví dụ room_id=184, dormitory_id=1).
      final dynamic studentAccommodations = rawStudent['accommodations'];
      if (studentAccommodations is List) {
        for (final dynamic raw in studentAccommodations) {
          inspectAccommodation(raw);
          if (roomId != null && dormitoryId != null) break;
        }
      }
    }

    // data.accommodations là summary camelCase; dùng làm fallback.
    final dynamic rawAccommodations = rawData['accommodations'];
    if (rawAccommodations is List) {
      for (final dynamic raw in rawAccommodations) {
        inspectAccommodation(raw);
        if (roomId != null && dormitoryId != null) break;
      }
    }

    _residenceContext = _KtxIssueResidenceContext(
      dormitoryId: dormitoryId,
      roomId: roomId,
      assignedRoom: assignedRoom,
      source: source,
    );

    logInfo(
      '[KTX_ISSUE_RESIDENCE] source=$source '
      'dormitoryId=$dormitoryId roomId=$roomId '
      'assignedRoom=${assignedRoom.isEmpty ? '<empty>' : assignedRoom}',
    );
  }

  Future<_KtxIssueResidenceContext> _resolveResidenceContextIfNeeded() async {
    _KtxIssueResidenceContext context =
        _residenceContext ?? const _KtxIssueResidenceContext(source: 'none');

    if (context.roomId != null) return context;

    final Map<String, dynamic> query = _studentIdentityQuery();

    if (query.isNotEmpty) {
      try {
        final Response<Map<String, dynamic>> response = await _authorizedGet(
          'dormitory/me',
          queryParameters: query,
        );
        _captureResidenceContext(response.data, source: 'dormitory/me:create');
        context = _residenceContext ?? context;
      } catch (error) {
        logWarning('[KTX_ISSUE_RESIDENCE] dormitory/me create lookup failed: $error');
      }
    }

    if (context.roomId == null && context.assignedRoom.isNotEmpty) {
      try {
        final Response<Map<String, dynamic>> response = await _authorizedGet(
          'dormitory/rooms',
          queryParameters: const <String, dynamic>{'size': 1000},
        );
        final dynamic rawData = response.data?['data'];
        final dynamic rawItems = rawData is Map ? rawData['items'] : null;
        if (rawItems is List) {
          for (final dynamic raw in rawItems) {
            if (raw is! Map) continue;
            final String roomNumber =
                (raw['roomNumber'] ?? raw['room_number'] ?? '').toString().trim();
            final int? candidateDormitoryId =
                _positiveInt(raw['dormitoryId'] ?? raw['dormitory_id']);
            if (roomNumber == context.assignedRoom &&
                (context.dormitoryId == null ||
                    candidateDormitoryId == context.dormitoryId)) {
              final int? candidateRoomId = _positiveInt(raw['id']);
              if (candidateRoomId != null) {
                context = _KtxIssueResidenceContext(
                  dormitoryId: context.dormitoryId ?? candidateDormitoryId,
                  roomId: candidateRoomId,
                  assignedRoom: context.assignedRoom,
                  source: 'dormitory/rooms',
                );
                _residenceContext = context;
                break;
              }
            }
          }
        }
      } catch (error) {
        logWarning('[KTX_ISSUE_RESIDENCE] room lookup failed: $error');
      }
    }

    logInfo(
      '[KTX_ISSUE_RESIDENCE_FINAL] '
      'dormitoryId=${context.dormitoryId} roomId=${context.roomId} '
      'assignedRoom=${context.assignedRoom.isEmpty ? '<empty>' : context.assignedRoom} '
      'source=${context.source}',
    );
    return context;
  }

  int? _positiveInt(dynamic value) {
    final int? parsed = int.tryParse((value ?? '').toString());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  String _maskedIdentity(String value) {
    final String text = value.trim();
    if (text.isEmpty) return '<empty>';
    if (text.length <= 4) return '***$text';
    return '***${text.substring(text.length - 4)}';
  }

  String _maskedIdentifier(String value) {
    final String studentCode = _studentCode();
    if (value == studentCode && studentCode.isNotEmpty) return studentCode;
    return _maskedIdentity(value);
  }

  String _shortLog(dynamic value) {
    final String text = value?.toString() ?? '<null>';
    const int maxLength = 1200;
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';
  }

  String absoluteMediaUrl(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return '';

    final Uri? uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return uri.toString();
    }

    final String host = ServicesUrl().effectiveKtxHostUrl;
    if (host.isEmpty) return value;

    final String base = host.endsWith('/') ? host : '$host/';
    final String relative = value.startsWith('/') ? value.substring(1) : value;
    return '$base$relative';
  }

  Future<Response<Map<String, dynamic>>> _authorizedGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _with401Retry<Response<Map<String, dynamic>>>(() async {
      final String token = await _requireAccessToken();
      final Dio client = await _client();

      logInfo(
        '[KTX_ISSUE_REQUEST] GET $path '
        'auth=true tokenLength=${token.length} '
        'query=${_safeQueryLog(queryParameters)}',
      );

      return client.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: _jsonOptions(token),
      );
    });
  }

  Future<Response<Map<String, dynamic>>> _authorizedPost(
    String path, {
    required dynamic data,
    bool multipart = false,
  }) {
    return _with401Retry<Response<Map<String, dynamic>>>(() async {
      final String token = await _requireAccessToken();
      final Dio client = await _client();

      logInfo(
        '[KTX_ISSUE_REQUEST] POST $path '
        'auth=true tokenLength=${token.length} multipart=$multipart',
      );

      return client.post<Map<String, dynamic>>(
        path,
        data: data,
        options: multipart
            ? _multipartOptions(token)
            : _jsonOptions(token),
      );
    });
  }

  /// Retry đúng một lần khi access token ONEVNU hết hạn.
  Future<T> _with401Retry<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;

      logWarning(
        '[KTX_ISSUE_AUTH] KTX trả 401, thử refresh access token 1 lần.',
      );

      final bool refreshed = await _refreshAccessToken();
      if (!refreshed) rethrow;

      return request();
    }
  }

  Future<Dio> _client() async {
    await AppConfigService().ensureLoaded();

    final String configured = ServicesUrl().effectiveKtxApiUrl.trim();
    if (configured.isEmpty) {
      throw const KtxIssueApiException(
        'Chưa có địa chỉ API KTX. Vui lòng tải lại cấu hình ứng dụng.',
      );
    }

    final String baseUrl = configured.endsWith('/')
        ? configured
        : '$configured/';

    if (_dio == null || _baseUrl != baseUrl) {
      _dio?.close(force: true);

      // P4.3 R2 dùng Dio riêng cho KTX Issue để Authorization header không bị
      // một interceptor của ONEVNU thay/ghi đè. Header Bearer được gắn rõ ở
      // từng request bằng _jsonOptions/_multipartOptions.
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
          headers: const <String, dynamic>{
            'Accept': 'application/json',
          },
        ),
      );

      _baseUrl = baseUrl;
      debugPrint('[KTX_ISSUE] API base URL: $baseUrl');
    }

    return _dio!;
  }

  Future<String> _requireAccessToken() async {
    String token = Globals().token.trim();

    if (token.isEmpty) {
      final String? stored =
          await DataRepository().getSecureSaveKey(kLoginToken);
      token = stored?.trim() ?? '';

      if (token.isNotEmpty) {
        Globals().token = token;
        ApiRepository().setToken(token);
      }
    }

    if (token.isEmpty) {
      throw const KtxIssueApiException(
        'Không tìm thấy access token đăng nhập. Vui lòng đăng nhập lại để xem phản ánh KTX của bạn.',
        statusCode: 401,
      );
    }

    return token;
  }

  Future<bool> _refreshAccessToken() async {
    try {
      String refreshToken = Globals().refreshToken.trim();
      if (refreshToken.isEmpty) {
        refreshToken =
            (await DataRepository().getSecureSaveKey(kLoginRefreshToken))
                    ?.trim() ??
                '';
      }

      if (refreshToken.isEmpty) {
        logWarning('[KTX_ISSUE_AUTH] Không có refresh token.');
        return false;
      }

      final response = await ApiRepository().refreshToken(refreshToken);
      final String newAccessToken = response.accessToken?.trim() ?? '';
      final String newRefreshToken = response.refreshToken?.trim() ?? '';

      if (newAccessToken.isEmpty) {
        logWarning(
          '[KTX_ISSUE_AUTH] Refresh response không có access token.',
        );
        return false;
      }

      Globals().token = newAccessToken;
      ApiRepository().setToken(newAccessToken);

      if (newRefreshToken.isNotEmpty) {
        Globals().refreshToken = newRefreshToken;
      }

      final List<Future<void>> writes = <Future<void>>[
        DataRepository().saveSecureKey(kLoginToken, newAccessToken),
      ];
      if (newRefreshToken.isNotEmpty) {
        writes.add(
          DataRepository().saveSecureKey(
            kLoginRefreshToken,
            newRefreshToken,
          ),
        );
      }
      await Future.wait<void>(writes);

      logInfo(
        '[KTX_ISSUE_AUTH] Refresh access token thành công '
        'tokenLength=${newAccessToken.length}.',
      );
      return true;
    } catch (error, stackTrace) {
      logError(
        '[KTX_ISSUE_AUTH] Refresh access token thất bại: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  String _studentCode() {
    final String fromStudent =
        Globals().thongTinSinhVienModel.value?.maSinhVien?.trim() ?? '';
    if (fromStudent.isNotEmpty) return fromStudent;
    return Globals().usernameLogin.trim();
  }

  String _identityNo() {
    return Globals().thongTinSinhVienModel.value?.soCmtCccd?.trim() ?? '';
  }

  Map<String, dynamic> _studentIdentityQuery() {
    final String studentCode = _studentCode();
    final String identityNo = _identityNo();

    final Map<String, dynamic> query = <String, dynamic>{};
    if (studentCode.isNotEmpty) {
      query['student_code'] = studentCode;
    }
    if (identityNo.isNotEmpty) {
      query['identity_no'] = identityNo;
    }

    if (query.isEmpty) {
      throw const KtxIssueApiException(
        'Không xác định được mã sinh viên hoặc CCCD để truy cập phản ánh KTX.',
        statusCode: 422,
      );
    }

    return query;
  }

  Map<String, dynamic>? _queryFromPaginatorUrl(String? rawUrl) {
    final String value = rawUrl?.trim() ?? '';
    if (value.isEmpty) return null;

    final Uri? uri = Uri.tryParse(value);
    if (uri == null || uri.queryParameters.isEmpty) return null;

    // Chỉ giữ query pagination/filter mà backend trả về.
    // Không lấy host/path từ next_page_url để tránh request sang host lạ.
    return Map<String, dynamic>.from(uri.queryParameters);
  }

  void _addField(FormData formData, String key, dynamic value) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    formData.fields.add(MapEntry<String, String>(key, value.toString()));
  }

  String _safeQueryLog(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return '{}';
    final Map<String, dynamic> safe = Map<String, dynamic>.from(query);
    if (safe.containsKey('identity_no')) {
      safe['identity_no'] = _maskedIdentity(safe['identity_no']?.toString() ?? '');
    }
    return safe.toString();
  }

  Options _jsonOptions(String token) {
    return Options(
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Options _multipartOptions(String token) {
    return Options(
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      contentType: Headers.multipartFormDataContentType,
    );
  }

  KtxIssueApiException _mapDioException(DioException error) {
    final int? statusCode = error.response?.statusCode;
    final dynamic data = error.response?.data;

    String message = '';
    dynamic errors;

    if (data is Map) {
      message = data['message']?.toString().trim() ?? '';
      errors = data['errors'];
    }

    if (statusCode == 401) {
      message =
          'Phiên đăng nhập không được KTX chấp nhận hoặc đã hết hạn. Vui lòng đăng nhập lại.';
    } else if (statusCode == 403 && message.isEmpty) {
      message = 'Bạn không có quyền truy cập phản ánh KTX này.';
    }

    if (message.isEmpty) {
      message = error.message?.trim() ?? '';
    }
    if (message.isEmpty) {
      message = 'Không thể kết nối tới hệ thống KTX. Vui lòng thử lại.';
    }

    final bool hasAuthorization =
        error.requestOptions.headers.containsKey('Authorization');

    logError(
      '[KTX_ISSUE_API] status=$statusCode '
      'path=${error.requestOptions.path} '
      'auth=$hasAuthorization '
      'message=$message '
      'response=${_shortLog(data)}',
    );

    return KtxIssueApiException(
      message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

class _KtxIssueResidenceContext {
  final int? dormitoryId;
  final int? roomId;
  final String assignedRoom;
  final String source;

  const _KtxIssueResidenceContext({
    this.dormitoryId,
    this.roomId,
    this.assignedRoom = '',
    required this.source,
  });
}
