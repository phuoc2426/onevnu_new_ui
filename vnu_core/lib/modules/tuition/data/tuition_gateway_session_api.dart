import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/tuition/data/tuition_api_diagnostics.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_session_cache.dart';
import 'package:vnu_core/services/services_url.dart';

/// Calls ONEVNU's authenticated token-exchange endpoint, NOT the gateway's
/// API-key endpoint. No x-api-key, studentCode or university ID is sent by app.
class TuitionGatewaySessionApi {
  TuitionGatewaySessionApi({
    Dio? dio,
    TuitionGatewaySessionCache? cache,
    String Function()? oneVnuTokenProvider,
  })  : _dio = dio ?? Dio(BaseOptions(
          baseUrl: ServicesUrl().baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        )),
        _cache = cache ?? TuitionGatewaySessionCache.instance,
        _oneVnuTokenProvider = oneVnuTokenProvider ?? _currentOneVnuJwt;

  final Dio _dio;
  final TuitionGatewaySessionCache _cache;
  final String Function() _oneVnuTokenProvider;

  static String _currentOneVnuJwt() => Globals().token;

  /// Uses the RAM session unless expired or [forceRefresh] is true.
  /// An authenticated GET to CP1 that receives 401 uses forceRefresh=true.
  Future<TuitionGatewaySession> issueForCurrentStudent({
    bool forceRefresh = false,
  }) {
    final jwt = _oneVnuTokenProvider().trim();
    if (jwt.isEmpty) {
      _cache.clear();
      TuitionApiDiagnostics.instance.record(
        'SESSION', 'FAILED', note: 'no_onevnu_jwt');
      throw StateError('ONEVNU student login required');
    }
    if (!forceRefresh && _cache.hasUsableSession(jwt)) {
      TuitionApiDiagnostics.instance.record('SESSION', 'CACHE_HIT');
    }
    return _cache.getOrIssue(
      oneVnuJwt: jwt,
      forceRefresh: forceRefresh,
      issue: () => _requestFromBackend(jwt),
    );
  }

  Future<TuitionGatewaySession> _requestFromBackend(String jwt) async {
    final trace = TuitionApiDiagnostics.instance;
    final stopwatch = Stopwatch()..start();
    trace.record('SESSION', 'START', note: 'onevnu_backend');
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        'api/ulis-tuition/session',
        options: Options(headers: <String, String>{
          'Authorization': 'Bearer $jwt',
          if (!kIsWeb) 'Cache-Control': 'no-store',
        }),
      );
    } on DioException catch (error) {
      trace.record('SESSION', 'FAILED',
        statusCode: error.response?.statusCode,
        elapsedMs: stopwatch.elapsedMilliseconds,
        note: error.type.name);
      rethrow;
    } catch (_) {
      trace.record('SESSION', 'FAILED',
        elapsedMs: stopwatch.elapsedMilliseconds,
        note: 'client_exception');
      rethrow;
    }

    final raw = response.data;
    if (raw is! Map) {
      trace.record('SESSION', 'FAILED',
        statusCode: response.statusCode,
        elapsedMs: stopwatch.elapsedMilliseconds,
        note: 'invalid_response');
      throw const FormatException('Invalid ULIS session response');
    }
    var data = Map<String, dynamic>.from(raw);
    for (var depth = 0; depth < 2; depth++) {
      final nested = data['data'] ?? data['result'];
      if (nested is! Map) break;
      data = Map<String, dynamic>.from(nested);
    }
    final universityId = int.tryParse('${data['universityId'] ?? ''}') ?? -1;
    final ttl = int.tryParse('${data['expiresIn'] ?? data['expires_in'] ?? ''}');
    final expiryText = (data['expiresAtUtc'] ?? data['expiresAt'])?.toString();
    DateTime? expiresAt = DateTime.tryParse(expiryText ?? '')?.toUtc();
    if (expiresAt == null && ttl != null && ttl > 0) {
      expiresAt = DateTime.now().toUtc().add(Duration(seconds: ttl));
    }
    final session = TuitionGatewaySession(
      accessToken: (data['accessToken'] ?? data['access_token'] ?? '').toString(),
      canonicalStudentId: (data['canonicalStudentId'] ?? '').toString(),
      universityId: universityId,
      expiresAtUtc: expiresAt,
    );
    if (!session.isValid) {
      trace.record('SESSION', 'FAILED',
        statusCode: response.statusCode,
        elapsedMs: stopwatch.elapsedMilliseconds,
        note: 'invalid_session_shape');
      throw StateError('ONEVNU did not return a valid ULIS payment session');
    }
    trace.record('SESSION', 'OK', statusCode: response.statusCode,
      elapsedMs: stopwatch.elapsedMilliseconds);
    return session;
  }
}
