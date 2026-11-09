import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vnu_core/modules/one_door/data/one_door_api_debug.dart';
import 'package:vnu_core/modules/one_door/data/one_door_docx_fill.dart';
import 'package:vnu_core/modules/one_door/data/one_door_live_api.dart';

/// One Door OpenAPI 2026-11-08. This client only reads the form schema and
/// creates PRE-SUBMISSION documents. It never submits a registration.
class OneDoorDynamicField {
  const OneDoorDynamicField({
    required this.key, required this.label, required this.type,
    required this.required, required this.hint, required this.previousValue,
  });
  final String key;
  final String label;
  final String type;
  final bool required;
  final String hint;
  final String previousValue;

  factory OneDoorDynamicField.fromJson(Map<String, dynamic> value) {
    final key = (value['key'] ?? '').toString().trim();
    return OneDoorDynamicField(
      key: key,
      label: (value['nhan'] ?? key).toString(),
      type: (value['loai'] ?? 'text').toString().toLowerCase(),
      required: value['batBuoc'] == true,
      hint: (value['goiY'] ?? '').toString(),
      previousValue: (value['giaTriTruoc'] ?? '').toString(),
    );
  }
}

class OneDoorReason {
  const OneDoorReason(this.id, this.label);
  final int id;
  final String label;
}

class OneDoorFormConfiguration {
  const OneDoorFormConfiguration({
    this.fields = const <OneDoorDynamicField>[],
    this.autoPaperIds = const <String>{},
    this.reasons = const <OneDoorReason>[],
    this.tuitionBlocked = false,
  });
  final List<OneDoorDynamicField> fields;
  final Set<String> autoPaperIds;
  final List<OneDoorReason> reasons;
  final bool tuitionBlocked;
}

class OneDoorFilledDocument {
  const OneDoorFilledDocument(this.bytes, this.extension);
  final List<int> bytes;
  final String extension;
}

class OneDoorFormApi {
  OneDoorFormApi(OneDoorSession session, {
    Future<OneDoorSession> Function()? refreshSession,
    Dio? dio,
  }) : _session = session,
       _refreshSession = refreshSession,
       _dio = dio ?? Dio(BaseOptions(
         baseUrl: 'https://motcua-vnu.digitaledu.vn/mc-api',
         connectTimeout: const Duration(seconds: 20),
         receiveTimeout: const Duration(seconds: 35),
       )) {
    OneDoorApiDebug.instance.attach(_dio, 'Một cửa · biểu mẫu');
  }

  final Dio _dio;
  OneDoorSession _session;
  final Future<OneDoorSession> Function()? _refreshSession;

  Options _headers({ResponseType? responseType}) => Options(
    responseType: responseType,
    headers: <String, String>{
      'Authorization': 'Bearer ${_session.accessToken}',
    },
  );

  Future<void> _refreshIfNeeded() async {
    if (_session.expiresSoon && _refreshSession != null) {
      _session = await _refreshSession!();
      if (!_session.isValid) throw StateError('Phiên Một cửa không hợp lệ');
    }
  }

  Future<dynamic> _get(String path) async {
    await _refreshIfNeeded();
    try {
      return (await _dio.get<dynamic>(path, options: _headers())).data;
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || _refreshSession == null) rethrow;
      _session = await _refreshSession!();
      return (await _dio.get<dynamic>(path, options: _headers())).data;
    }
  }

  Map<String, dynamic> _object(dynamic raw) {
    if (raw is! Map) throw const FormatException('Phản hồi JSON không hợp lệ');
    var value = Map<String, dynamic>.from(raw);
    for (var i = 0; i < 2; i++) {
      final inner = value['data'] ?? value['result'];
      if (inner is! Map) break;
      value = Map<String, dynamic>.from(inner);
    }
    return value;
  }

  Future<OneDoorFormConfiguration> load(String procedureId) async {
    final data = _object(await _get(
      '/api/v1/ho-so/dieu-kien-nop/${Uri.encodeComponent(procedureId)}'));
    final fields = <OneDoorDynamicField>[];
    final seen = <String>{};
    for (final raw in data['bienCanNhaps'] is List
        ? data['bienCanNhaps'] as List : const <dynamic>[]) {
      if (raw is! Map) continue;
      final field = OneDoorDynamicField.fromJson(Map<String, dynamic>.from(raw));
      if (field.key.isEmpty || !seen.add(field.key.toLowerCase())) continue;
      fields.add(field);
    }
    final autoIds = <String>{};
    for (final value in data['giayToTuDien'] is List
        ? data['giayToTuDien'] as List : const <dynamic>[]) {
      final id = value.toString().trim();
      if (id.isNotEmpty) autoIds.add(id);
    }
    final reasons = <OneDoorReason>[];
    for (final raw in data['lyDos'] is List
        ? data['lyDos'] as List : const <dynamic>[]) {
      if (raw is! Map) continue;
      final id = int.tryParse('${raw['idLyDo'] ?? ''}');
      final label = (raw['tenLyDo'] ?? '').toString().trim();
      if (id != null && label.isNotEmpty) {
        reasons.add(OneDoorReason(id, label));
      }
    }
    final tuition = data['noHocPhi'];
    return OneDoorFormConfiguration(fields: fields, autoPaperIds: autoIds,
      reasons: reasons,
      tuitionBlocked: tuition is Map && tuition['vuotMuc'] == true);
  }

  /// Missing saved values are not a reason to block the form; schema is.
  Future<Map<String, String>> savedValues() async {
    final raw = await _get('/api/v1/bien-bieu-mau/cua-toi');
    final values = <String, String>{};
    final data = raw is Map ? _object(raw) : raw;
    final rows = data is List ? data :
      (data is Map && data['items'] is List ? data['items'] as List : const <dynamic>[]);
    for (final entry in rows) {
      if (entry is! Map) continue;
      final key = (entry['key'] ?? '').toString().trim();
      final value = (entry['giaTri'] ?? '').toString();
      if (key.isNotEmpty && value.isNotEmpty) values[key] = value;
    }
    return values;
  }

  /// POST accepts a simple string-to-string JSON map according to OpenAPI.
  /// An unexpected 401 is surfaced, never automatically replayed.
  Future<OneDoorFilledDocument> generate(String paperId,
      Map<String, String> values) async {
    await _refreshIfNeeded();
    final uri = '/api/v1/files/giay-to-mau/'
      '${Uri.encodeComponent(paperId)}/da-dien';
    final response = await _dio.post<List<int>>(uri,
      data: values,
      options: _headers(responseType: ResponseType.bytes).copyWith(
        contentType: Headers.jsonContentType));
    final bytes = response.data ?? <int>[];
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Tệp tự điền rỗng hoặc vượt quá 10 MB');
    }
    // Binary signatures protect against accidentally saving JSON/HTML errors
    // as .docx and subsequently uploading them as official documents.
    final prefix = bytes.take(8).toList();
    final isZip = prefix.length >= 4 && prefix[0] == 0x50 &&
        prefix[1] == 0x4b && prefix[2] == 0x03 && prefix[3] == 0x04;
    final isPdf = prefix.length >= 4 && prefix[0] == 0x25 &&
        prefix[1] == 0x50 && prefix[2] == 0x44 && prefix[3] == 0x46;
    final isOle = prefix.length >= 8 && prefix[0] == 0xd0 &&
        prefix[1] == 0xcf && prefix[2] == 0x11 && prefix[3] == 0xe0;
    final isPng = prefix.length >= 4 && prefix[0] == 0x89 &&
        prefix[1] == 0x50 && prefix[2] == 0x4e && prefix[3] == 0x47;
    final isJpeg = prefix.length >= 3 && prefix[0] == 0xff &&
        prefix[1] == 0xd8 && prefix[2] == 0xff;
    if (!isZip && !isPdf && !isOle && !isPng && !isJpeg) {
      throw const FormatException('API không trả về tệp tài liệu hợp lệ');
    }
    final contentType = response.headers.value(Headers.contentTypeHeader)
      ?.toLowerCase() ?? '';
    final extension = isPdf ? 'pdf' : isPng ? 'png' : isJpeg ? 'jpg'
      : isOle ? 'doc' : (contentType.contains('spreadsheet') ||
         contentType.contains('excel') ? 'xlsx' : 'docx');
    // V28: HTTP 200 is not proof that Word used the selected reason.
    // Inspect the actual DOCX, repair remaining placeholders locally, and if
    // the server stripped the placeholder without filling it, rebuild from
    // the official unfilled template. The resulting bytes are exactly the
    // bytes the screen previews AND submits as its attachment.
    if (extension == 'docx') {
      return _ensureFilledWord(paperId, bytes, values);
    }
    return OneDoorFilledDocument(bytes, extension);
  }

  Future<List<int>> _downloadUnfilledTemplate(String paperId) async {
    await _refreshIfNeeded();
    final uri = '/api/v1/files/giay-to-mau/${Uri.encodeComponent(paperId)}';
    Future<Response<List<int>>> fetch() => _dio.get<List<int>>(uri,
      options: _headers(responseType: ResponseType.bytes));
    late Response<List<int>> response;
    try {
      response = await fetch();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || _refreshSession == null) rethrow;
      _session = await _refreshSession!();
      response = await fetch();
    }
    final bytes = response.data ?? <int>[];
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Mẫu Word gốc không hợp lệ.');
    }
    return bytes;
  }

  Future<OneDoorFilledDocument> _ensureFilledWord(String paperId,
      List<int> serverBytes, Map<String, String> values) async {
    final expected = (values['YeuCau'] ?? '').trim();
    // For templates without any YeuCau at all, server output stays intact.
    // A Word value is NEVER assumed to be filled merely because POST is 200.
    final local = OneDoorDocxFill.fill(serverBytes, values);
    if (expected.isEmpty) {
      return OneDoorFilledDocument(local.bytes, 'docx');
    }
    if (local.inspection.hasExpectedYeuCau &&
        !local.inspection.hasYeuCauPlaceholder) {
      OneDoorApiDebug.instance.note('V28 Kiểm tra YeuCau trong DOCX',
        <String, dynamic>{
          'paperId': paperId,
          'source': values.containsKey('IdLyDo')
              ? 'lyDos.tenLyDo' : 'noi_dung_de_nghi',
          'expectedCharacters': expected.length,
          'result': local.replacements > 0
              ? 'LOCAL_PLACEHOLDER_FILLED' : 'SERVER_ALREADY_FILLED',
          'localReplacements': local.replacements,
        });
      return OneDoorFilledDocument(local.bytes, 'docx');
    }

    // Backend may have turned {YeuCau} into an empty string before returning
    // the DOCX. In that case an in-place replacement is impossible; retrieve
    // the official raw template and fill its placeholders on device instead.
    final List<int> templateBytes;
    try {
      templateBytes = await _downloadUnfilledTemplate(paperId);
    } catch (error) {
      // With no dropdown reason, the DOCX may not even contain {YeuCau}.
      // Do not block unrelated forms solely because the optional template
      // inspection request failed. A selected reason is stricter: never
      // confirm an unverified Word document for that case.
      if (values['IdLyDo']?.trim().isNotEmpty == true) rethrow;
      OneDoorApiDebug.instance.note('V28 Không tải được Word mẫu để đối chiếu',
        <String, dynamic>{'paperId': paperId,
          'errorType': error.runtimeType.toString()});
      return OneDoorFilledDocument(local.bytes, 'docx');
    }
    final templateCheck = OneDoorDocxFill.inspect(templateBytes, expected);
    if (!templateCheck.hasMainDocument) {
      throw const FormatException('Mẫu Word gốc thiếu nội dung tài liệu.');
    }
    if (!templateCheck.hasYeuCauPlaceholder) {
      // The Word template never asks for {YeuCau}. Do not invent a location.
      OneDoorApiDebug.instance.note('V28 Kiểm tra YeuCau trong DOCX',
        <String, dynamic>{'paperId': paperId,
          'result': 'TEMPLATE_HAS_NO_YEUCAU',
          'expectedCharacters': expected.length});
      return OneDoorFilledDocument(local.bytes, 'docx');
    }
    final fallback = OneDoorDocxFill.fill(templateBytes, values);
    if (!fallback.inspection.hasExpectedYeuCau ||
        fallback.inspection.hasYeuCauPlaceholder) {
      OneDoorApiDebug.instance.note('V28 Kiểm tra YeuCau trong DOCX',
        <String, dynamic>{'paperId': paperId,
          'result': 'UNRESOLVED_PLACEHOLDER'});
      throw StateError('Không điền được lý do vào mẫu Word gốc.');
    }
    OneDoorApiDebug.instance.note('V28 Kiểm tra YeuCau trong DOCX',
      <String, dynamic>{'paperId': paperId,
        'source': values.containsKey('IdLyDo')
            ? 'lyDos.tenLyDo' : 'noi_dung_de_nghi',
        'expectedCharacters': expected.length,
        'result': 'LOCAL_OFFICIAL_TEMPLATE_FALLBACK',
        'localReplacements': fallback.replacements});
    return OneDoorFilledDocument(fallback.bytes, 'docx');
  }
}
