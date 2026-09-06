import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/qr/models/qr_action_model.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_client_metadata_service.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

const String kQrErrorIdpReauthRequired = 'IDP_REAUTH_REQUIRED';
const String kQrErrorChallengeStale = 'QR_CHALLENGE_STALE';
const String kQrErrorIdpChallengeNotReady = 'IDP_CHALLENGE_NOT_READY';
const String kQrErrorChallengeUnavailable = 'QR_CHALLENGE_UNAVAILABLE';
const String kQrErrorExpired = 'QR_EXPIRED';
const String kQrErrorAlreadyUsed = 'QR_ALREADY_USED';
const String kQrErrorOutcomeUnknown = 'QR_OUTCOME_UNKNOWN';
const String kQrErrorExecutionInProgress = 'QR_EXECUTION_IN_PROGRESS';
const String kQrErrorDeviceMismatch = 'QR_DEVICE_MISMATCH';
const String kQrErrorDeviceBindingRequired = 'QR_DEVICE_BINDING_REQUIRED';
const String kQrErrorTemporary = 'IDP_TEMPORARY_ERROR';
const String kQrErrorInvalidFormat = 'QR_INVALID_FORMAT';
const String kQrErrorInvalidPayload = 'QR_INVALID_PAYLOAD';
const String kQrErrorUnsupported = 'QR_UNSUPPORTED';
const String kQrErrorSecurityPolicyRejected = 'QR_SECURITY_POLICY_REJECTED';

class QrApiException implements Exception {
  const QrApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.requestId,
    this.flowId,
    this.providerStatus,
    this.providerError,
    this.providerRequestId,
    this.failureStage,
    this.classification,
    this.retryable,
    this.userAction,
    this.outcome,
    this.networkKind,
    this.retryAfterMs,
    this.waitElapsedMs,
    this.graceMs,
    this.attempt,
    this.maxAttempts,
  });

  final String code;
  final String message;
  final int? statusCode;
  final String? requestId;
  final String? flowId;
  final int? providerStatus;
  final String? providerError;
  final String? providerRequestId;
  final String? failureStage;
  final String? classification;
  final bool? retryable;
  final String? userAction;
  final String? outcome;
  final String? networkKind;
  final int? retryAfterMs;
  final int? waitElapsedMs;
  final int? graceMs;
  final int? attempt;
  final int? maxAttempts;

  @override
  String toString() => message;
}

class QrRepository {
  QrRepository._internal()
      : _dio = DioOptions().createDio(ServicesUrl().baseUrl);

  static final QrRepository _instance = QrRepository._internal();

  factory QrRepository() => _instance;

  final Dio _dio;

  Future<QrResolvedAction> resolve(
    String rawQr, {
    required String flowId,
  }) async {
    final String traceId = const Uuid().v4();
    final Stopwatch stopwatch = Stopwatch()..start();
    final Map<String, dynamic> clientHeaders =
        await IdpClientMetadataService().headers(
      requestId: traceId,
      flowId: flowId,
    );
    _trace(
      'RESOLVE_REQUEST',
      'flowId=$flowId rid=$traceId rawLength=${rawQr.length} endpoint=/api/qr/resolve',
    );

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/qr/resolve',
        data: <String, dynamic>{'raw': rawQr},
        options: Options(headers: clientHeaders),
      );

      final String backendRid = _requestId(response, traceId);
      _trace(
        'RESOLVE_HTTP',
        'flowId=$flowId rid=$backendRid status=${response.statusCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds} shape=${_bodyShape(response.data)}',
      );

      final Map<String, dynamic> data = _unwrap(response.data);
      final QrResolvedAction result = QrResolvedAction.fromJson(data);

      if (result.sessionId.isEmpty) {
        throw StateError('Backend QR không trả sessionId.');
      }

      _trace(
        'RESOLVE_PARSED',
        'flowId=$flowId rid=$backendRid session=${_sessionPrefix(result.sessionId)} '
        'provider=${result.provider} type=${result.type} '
        'requiresConfirmation=${result.requiresConfirmation} '
        'localAuthRequired=${result.localAuthenticationRequired} '
        'contextVerified=${result.requestingContextVerified} '
        'requestingHost=${result.requestingHost ?? "none"} '
        'status=${result.status} expiresAt=${result.expiresAt} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );

      return result;
    } on DioException catch (error, stackTrace) {
      final QrApiException? api = _toApiException(error, traceId, flowId);
      _traceDio(
        'RESOLVE_DIO_ERROR',
        error,
        traceId,
        flowId,
        stopwatch.elapsedMilliseconds,
        api,
      );
      _traceStack(stackTrace);
      if (api != null) throw api;
      rethrow;
    } catch (error, stackTrace) {
      _trace(
        'RESOLVE_ERROR',
        'flowId=$flowId rid=$traceId type=${error.runtimeType} message=${_safeText(error.toString())} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  Future<QrExecutionResult> execute(
    String sessionId, {
    required String flowId,
  }) async {
    final String traceId = const Uuid().v4();
    final Stopwatch stopwatch = Stopwatch()..start();
    final Map<String, dynamic> clientHeaders =
        await IdpClientMetadataService().headers(
      requestId: traceId,
      flowId: flowId,
    );
    _trace(
      'EXECUTE_REQUEST',
      'flowId=$flowId rid=$traceId session=${_sessionPrefix(sessionId)} '
      'endpoint=/api/qr/${_sessionPrefix(sessionId)}/execute',
    );

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/qr/$sessionId/execute',
        options: Options(headers: clientHeaders),
      );

      final String backendRid = _requestId(response, traceId);
      final Map<String, dynamic>? responseRoot = _asMap(response.data);
      final QrApiException? acceptedState = responseRoot == null
          ? null
          : _toApiExceptionFromMap(
              responseRoot,
              response.statusCode,
              backendRid,
              flowId,
            );
      if (response.statusCode == 202 && acceptedState != null) {
        _trace(
          'EXECUTE_ACCEPTED_STATE',
          'flowId=${acceptedState.flowId ?? flowId} rid=${acceptedState.requestId ?? backendRid} '
          'session=${_sessionPrefix(sessionId)} code=${acceptedState.code} '
          'classification=${acceptedState.classification ?? "none"} '
          'providerStatus=${acceptedState.providerStatus ?? "none"} '
          'providerError=${_safeText(acceptedState.providerError ?? "none")} '
          'retryAfterMs=${acceptedState.retryAfterMs ?? "none"} '
          'waitElapsedMs=${acceptedState.waitElapsedMs ?? "none"} '
          'graceMs=${acceptedState.graceMs ?? "none"} '
          'attempt=${acceptedState.attempt ?? "none"}/${acceptedState.maxAttempts ?? "none"} '
          'elapsedMs=${stopwatch.elapsedMilliseconds}',
        );
        throw acceptedState;
      }

      final Map<String, dynamic> data = _unwrap(response.data);
      final QrExecutionResult result = QrExecutionResult.fromJson(data);

      _trace(
        'EXECUTE_OK',
        'flowId=$flowId rid=$backendRid session=${_sessionPrefix(sessionId)} '
        'httpStatus=${response.statusCode} resultStatus=${result.status} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return result;
    } on QrApiException catch (api) {
      _trace(
        'EXECUTE_API_STATE',
        'flowId=${api.flowId ?? flowId} rid=${api.requestId ?? traceId} '
        'session=${_sessionPrefix(sessionId)} code=${api.code} '
        'classification=${api.classification ?? "none"} retryable=${api.retryable ?? "none"} '
        'retryAfterMs=${api.retryAfterMs ?? "none"} elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      rethrow;
    } on DioException catch (error, stackTrace) {
      final QrApiException? api = _toApiException(error, traceId, flowId);
      _traceDio(
        'EXECUTE_DIO_ERROR',
        error,
        traceId,
        flowId,
        stopwatch.elapsedMilliseconds,
        api,
      );
      _traceStack(stackTrace);
      if (api != null) throw api;
      rethrow;
    } catch (error, stackTrace) {
      _trace(
        'EXECUTE_ERROR',
        'flowId=$flowId rid=$traceId session=${_sessionPrefix(sessionId)} '
        'type=${error.runtimeType} message=${_safeText(error.toString())} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  Future<void> cancel(
    String sessionId, {
    required String flowId,
  }) async {
    final String traceId = const Uuid().v4();
    final Stopwatch stopwatch = Stopwatch()..start();
    final Map<String, dynamic> clientHeaders =
        await IdpClientMetadataService().headers(
      requestId: traceId,
      flowId: flowId,
    );
    _trace(
      'CANCEL_REQUEST',
      'flowId=$flowId rid=$traceId session=${_sessionPrefix(sessionId)}',
    );
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/qr/$sessionId/cancel',
        options: Options(headers: clientHeaders),
      );
      _trace(
        'CANCEL_HTTP',
        'flowId=$flowId rid=${_requestId(response, traceId)} '
        'session=${_sessionPrefix(sessionId)} status=${response.statusCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    } on DioException catch (error, stackTrace) {
      final QrApiException? api = _toApiException(error, traceId, flowId);
      _traceDio(
        'CANCEL_DIO_ERROR',
        error,
        traceId,
        flowId,
        stopwatch.elapsedMilliseconds,
        api,
      );
      _traceStack(stackTrace);
      if (api != null) throw api;
      rethrow;
    }
  }

  QrApiException? _toApiException(
    DioException error,
    String fallbackRid,
    String fallbackFlowId,
  ) {
    final Map<String, dynamic>? root = _asMap(error.response?.data);
    if (root == null) return null;
    return _toApiExceptionFromMap(
      root,
      error.response?.statusCode,
      _requestId(error.response, fallbackRid),
      fallbackFlowId,
    );
  }

  QrApiException? _toApiExceptionFromMap(
    Map<String, dynamic> root,
    int? statusCode,
    String requestId,
    String fallbackFlowId,
  ) {
    final String code = _string(root, 'code', 'errorCode', 'error_code');
    if (code.isEmpty) return null;
    final String message =
        _string(root, 'message', 'errorMessage', 'error_description');

    return QrApiException(
      code: code,
      message: message.isEmpty ? 'Không thực hiện được yêu cầu QR.' : message,
      statusCode: statusCode,
      requestId: requestId,
      flowId: _string(root, 'flowId', 'flow_id').isEmpty
          ? fallbackFlowId
          : _string(root, 'flowId', 'flow_id'),
      providerStatus: _int(root, 'providerStatus', 'provider_status'),
      providerError: _nullableString(root, 'providerError', 'provider_error'),
      providerRequestId:
          _nullableString(root, 'providerRequestId', 'provider_request_id'),
      failureStage: _nullableString(root, 'failureStage', 'failure_stage'),
      classification: _nullableString(root, 'classification'),
      retryable: _bool(root, 'retryable'),
      userAction: _nullableString(root, 'userAction', 'user_action'),
      outcome: _nullableString(root, 'outcome'),
      networkKind: _nullableString(root, 'networkKind', 'network_kind'),
      retryAfterMs: _int(root, 'retryAfterMs', 'retry_after_ms'),
      waitElapsedMs: _int(root, 'waitElapsedMs', 'wait_elapsed_ms'),
      graceMs: _int(root, 'graceMs', 'grace_ms'),
      attempt: _int(root, 'attempt'),
      maxAttempts: _int(root, 'maxAttempts', 'max_attempts'),
    );
  }

  void _traceDio(
    String event,
    DioException error,
    String fallbackRid,
    String flowId,
    int elapsedMs,
    QrApiException? api,
  ) {
    _trace(
      event,
      'flowId=${api?.flowId ?? flowId} rid=${api?.requestId ?? _requestId(error.response, fallbackRid)} '
      'status=${error.response?.statusCode} dioType=${error.type} '
      'code=${api?.code ?? "none"} stage=${api?.failureStage ?? "none"} '
      'classification=${api?.classification ?? "none"} '
      'providerStatus=${api?.providerStatus ?? "none"} '
      'providerError=${_safeText(api?.providerError ?? "none")} '
      'providerRequestId=${_safeText(api?.providerRequestId ?? "none")} '
      'networkKind=${api?.networkKind ?? "none"} outcome=${api?.outcome ?? "none"} '
      'retryable=${api?.retryable ?? "none"} userAction=${api?.userAction ?? "none"} '
      'retryAfterMs=${api?.retryAfterMs ?? "none"} waitElapsedMs=${api?.waitElapsedMs ?? "none"} '
      'graceMs=${api?.graceMs ?? "none"} attempt=${api?.attempt ?? "none"}/${api?.maxAttempts ?? "none"} '
      'elapsedMs=$elapsedMs body=${_safeBody(error.response?.data)}',
    );
  }

  String _string(Map<String, dynamic> root, String key1, [String? key2, String? key3]) {
    for (final String? key in <String?>[key1, key2, key3]) {
      if (key == null) continue;
      final String value = root[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String? _nullableString(Map<String, dynamic> root, String key1, [String? key2]) {
    final String value = _string(root, key1, key2);
    return value.isEmpty ? null : value;
  }

  int? _int(Map<String, dynamic> root, String key1, [String? key2]) {
    final dynamic raw = root[key1] ?? (key2 == null ? null : root[key2]);
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  bool? _bool(Map<String, dynamic> root, String key) {
    final dynamic raw = root[key];
    if (raw is bool) return raw;
    if (raw == null) return null;
    if (raw.toString().toLowerCase() == 'true') return true;
    if (raw.toString().toLowerCase() == 'false') return false;
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final dynamic data = body['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }

  String _bodyShape(dynamic body) {
    final Map<String, dynamic>? root = _asMap(body);
    if (root == null) return 'type=${body.runtimeType}';
    final Map<String, dynamic>? data = _asMap(root['data']);
    return 'rootKeys=${_sortedKeys(root)} dataKeys=${data == null ? "[]" : _sortedKeys(data)}';
  }

  String _sortedKeys(Map<String, dynamic> map) {
    final List<String> keys = map.keys.map((Object key) => key.toString()).toList()
      ..sort();
    return keys.take(40).toList().toString();
  }

  String _requestId(Response<dynamic>? response, String fallback) {
    final dynamic data = response?.data;
    if (data is Map) {
      final String bodyRid =
          (data['requestId'] ?? data['request_id'])?.toString().trim() ?? '';
      if (bodyRid.isNotEmpty) return bodyRid;
    }
    final String headerRid =
        response?.headers.value('X-Request-Id')?.trim() ??
            response?.headers.value('x-request-id')?.trim() ??
            '';
    return headerRid.isEmpty ? fallback : headerRid;
  }

  String _safeBody(dynamic body) {
    if (body == null) return '<empty>';
    String value;
    try {
      value = body is String ? body : jsonEncode(body);
    } catch (_) {
      value = body.toString();
    }
    value = sanitizeLogMessage(value).replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    return value.length <= 1200 ? value : '${value.substring(0, 1200)}...';
  }

  String _safeText(String value) {
    final String safe = sanitizeLogMessage(value)
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .trim();
    return safe.length <= 400 ? safe : '${safe.substring(0, 400)}...';
  }

  String _sessionPrefix(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return 'none';
    return trimmed.length <= 8 ? trimmed : trimmed.substring(0, 8);
  }

  void _trace(String event, String details) {
    dlog('[ONEVNU_FORENSIC][FLUTTER_QR][$event] $details', wrapWidth: 1200);
  }

  void _traceStack(StackTrace stackTrace) {
    final String compact = stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(10)
        .join(' | ');
    dlog('[ONEVNU_FORENSIC][FLUTTER_QR][STACK] $compact', wrapWidth: 1200);
  }
}
