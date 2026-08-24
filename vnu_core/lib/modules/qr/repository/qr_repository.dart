import 'package:dio/dio.dart';
import 'package:vnu_core/modules/qr/models/qr_action_model.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

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
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/qr/$sessionId/execute',
    );
    return QrExecutionResult.fromJson(_unwrap(response.data));
  }

  Future<void> cancel(String sessionId) async {
    await _dio.post<dynamic>('/api/qr/$sessionId/cancel');
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
