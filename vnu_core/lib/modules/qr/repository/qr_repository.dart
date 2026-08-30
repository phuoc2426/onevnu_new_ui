import 'package:dio/dio.dart';
import 'package:vnu_core/modules/qr/models/qr_action_model.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

const String kQrErrorIdpReauthRequired = 'IDP_REAUTH_REQUIRED';

class QrApiException implements Exception {
  const QrApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class QrRepository {
  QrRepository._internal()
      : _dio = DioOptions().createDio(ServicesUrl().baseUrl);

  static final QrRepository _instance = QrRepository._internal();

  factory QrRepository() => _instance;

  final Dio _dio;

  Future<QrResolvedAction> resolve(String rawQr) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/qr/resolve',
      data: <String, dynamic>{'raw': rawQr},
    );

    final Map<String, dynamic> data = _unwrap(response.data);
    final QrResolvedAction result = QrResolvedAction.fromJson(data);

    if (result.sessionId.isEmpty) {
      throw StateError('Backend QR không trả sessionId.');
    }

    return result;
  }

  Future<QrExecutionResult> execute(String sessionId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/qr/$sessionId/execute',
      );
      return QrExecutionResult.fromJson(_unwrap(response.data));
    } on DioException catch (error) {
      final String code = _readMachineErrorCode(error.response?.data);
      if (code.isNotEmpty) {
        final String message = _readErrorMessage(error.response?.data);
        throw QrApiException(
          code: code,
          message: message.isEmpty
              ? 'Không thực hiện được yêu cầu QR.'
              : message,
          statusCode: error.response?.statusCode,
        );
      }
      rethrow;
    }
  }

  Future<void> cancel(String sessionId) async {
    await _dio.post<dynamic>('/api/qr/$sessionId/cancel');
  }

  String _readMachineErrorCode(dynamic body) {
    final Map<String, dynamic>? root = _asMap(body);
    if (root == null) return '';

    for (final Map<String, dynamic> candidate in _errorMaps(root)) {
      for (final String key in const <String>['errorCode', 'error_code', 'code']) {
        final dynamic raw = candidate[key];
        if (raw is! String) continue;
        final String value = raw.trim();
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  String _readErrorMessage(dynamic body) {
    final Map<String, dynamic>? root = _asMap(body);
    if (root == null) return '';

    for (final Map<String, dynamic> candidate in _errorMaps(root)) {
      for (final String key in const <String>[
        'message',
        'errorMessage',
        'error_description',
      ]) {
        final String value = candidate[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  Iterable<Map<String, dynamic>> _errorMaps(Map<String, dynamic> root) sync* {
    yield root;
    for (final String key in const <String>['data', 'error']) {
      final Map<String, dynamic>? nested = _asMap(root[key]);
      if (nested != null) yield nested;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final dynamic data = body['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }
}
