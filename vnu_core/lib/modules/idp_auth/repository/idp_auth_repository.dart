import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_client_metadata_service.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

class IdpAuthRepository {
  IdpAuthRepository._internal()
      : _dio = DioOptions().createDio(ServicesUrl().baseUrl);

  static final IdpAuthRepository _instance = IdpAuthRepository._internal();

  factory IdpAuthRepository() => _instance;

  final Dio _dio;

  /// Creates the backend-owned OAuth transaction and returns only the public
  /// authorization URL. PKCE verifier, nonce and IDP tokens remain on backend.
  ///
  /// forceLogin=true uses an authenticated QR endpoint so callback is bound to
  /// the currently logged-in ONEVNU user and another IDP account is rejected.
  Future<Uri> initLogin({
    required String deviceId,
    required String bindingChallenge,
    required bool forceLogin,
    String? flowId,
  }) async {
    final String endpoint = forceLogin
        ? '/api/qr/idp/reauth/init'
        : '/api/auth/idp/init';
    final String traceId = const Uuid().v4();
    final Stopwatch stopwatch = Stopwatch()..start();

    final Map<String, dynamic> clientHeaders =
        await IdpClientMetadataService().headers(
      requestId: traceId,
      flowId: flowId,
    );

    _trace(
      'INIT_REQUEST',
      'flowId=${flowId ?? "none"} rid=$traceId endpoint=$endpoint forceLogin=$forceLogin '
      'deviceIdLength=${deviceId.length} '
      'bindingChallengeLength=${bindingChallenge.length}',
    );

    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: <String, dynamic>{
          'deviceId': deviceId,
          'bindingChallenge': bindingChallenge,
          'forceLogin': forceLogin,
        },
        options: Options(
          headers: clientHeaders,
        ),
      );

      final String backendRid = _requestId(response, traceId);
      final String raw =
          response.data?['authorizationUrl']?.toString().trim() ?? '';
      final Uri? uri = Uri.tryParse(raw);

      _trace(
        'INIT_RESPONSE',
        'rid=$backendRid status=${response.statusCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds} '
        'authorizationHost=${uri?.host ?? "invalid"} '
        'authorizationPath=${uri?.path ?? "invalid"}',
      );

      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw StateError('Backend không trả authorization URL VNU IDP hợp lệ.');
      }
      return uri;
    } on DioException catch (error, stackTrace) {
      _traceDioError('INIT_ERROR', error, traceId, stopwatch.elapsedMilliseconds);
      _traceStack(stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _trace(
        'INIT_ERROR',
        'rid=$traceId type=${error.runtimeType} message=$error '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  /// Redeems a one-time ONEVNU ticket. IDP access/refresh tokens never leave
  /// backend. Possession binding makes a stolen App-Link ticket unusable.
  Future<SigninResponse> redeemTicket({
    required String ticket,
    required String bindingSecret,
    required String deviceId,
    String? flowId,
  }) async {
    final String traceId = const Uuid().v4();
    final Stopwatch stopwatch = Stopwatch()..start();

    final Map<String, dynamic> clientHeaders =
        await IdpClientMetadataService().headers(
      requestId: traceId,
      flowId: flowId,
    );

    _trace(
      'REDEEM_REQUEST',
      'flowId=${flowId ?? "none"} rid=$traceId endpoint=/api/auth/idp/redeem '
      'ticketLength=${ticket.length} bindingSecretLength=${bindingSecret.length} '
      'deviceIdLength=${deviceId.length} '
      'deviceTokenPresent=${(ServicesUrl().firebaseToken ?? "").trim().isNotEmpty}',
    );

    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        '/api/auth/idp/redeem',
        data: <String, dynamic>{
          'ticket': ticket,
          'bindingSecret': bindingSecret,
          'deviceId': deviceId,
          if ((ServicesUrl().firebaseToken ?? '').trim().isNotEmpty)
            'deviceToken': ServicesUrl().firebaseToken!.trim(),
          'deviceInfo': Platform.isAndroid
              ? 'Android'
              : Platform.isIOS
                  ? 'iOS'
                  : Platform.operatingSystem,
        },
        options: Options(
          headers: <String, dynamic>{
            ...clientHeaders,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final String backendRid = _requestId(response, traceId);
      final Map<String, dynamic> body =
          response.data ?? <String, dynamic>{};
      final SigninResponse result = SigninResponse.fromJson(body);
      final bool hasAccess = (result.accessToken ?? '').trim().isNotEmpty;
      final bool hasRefresh = (result.refreshToken ?? '').trim().isNotEmpty;

      _trace(
        'REDEEM_RESPONSE',
        'rid=$backendRid status=${response.statusCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds} '
        'hasAccessToken=$hasAccess hasRefreshToken=$hasRefresh',
      );

      if (!hasAccess || !hasRefresh) {
        throw StateError(
          'API /api/auth/idp/redeem không trả accessToken/refreshToken ONEVNU.',
        );
      }
      return result;
    } on DioException catch (error, stackTrace) {
      _traceDioError(
        'REDEEM_ERROR',
        error,
        traceId,
        stopwatch.elapsedMilliseconds,
      );
      _traceStack(stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _trace(
        'REDEEM_ERROR',
        'rid=$traceId type=${error.runtimeType} message=$error '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  /// Completes an account-bound QR re-authentication while preserving the
  /// currently active ONEVNU JWT/refresh pair. No new ONEVNU session is minted.
  Future<void> redeemReauthTicket({
    required String ticket,
    required String bindingSecret,
    required String deviceId,
    String? flowId,
  }) async {
    final String traceId = const Uuid().v4();
    final Stopwatch stopwatch = Stopwatch()..start();

    final Map<String, dynamic> clientHeaders =
        await IdpClientMetadataService().headers(
      requestId: traceId,
      flowId: flowId,
    );

    _trace(
      'REAUTH_REDEEM_REQUEST',
      'flowId=${flowId ?? "none"} rid=$traceId endpoint=/api/qr/idp/reauth/redeem '
      'ticketLength=${ticket.length} bindingSecretLength=${bindingSecret.length} '
      'deviceIdLength=${deviceId.length}',
    );

    try {
      final Response<void> response = await _dio.post<void>(
        '/api/qr/idp/reauth/redeem',
        data: <String, dynamic>{
          'ticket': ticket,
          'bindingSecret': bindingSecret,
          'deviceId': deviceId,
        },
        options: Options(
          headers: <String, dynamic>{
            ...clientHeaders,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      _trace(
        'REAUTH_REDEEM_RESPONSE',
        'rid=${_requestId(response, traceId)} status=${response.statusCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    } on DioException catch (error, stackTrace) {
      _traceDioError(
        'REAUTH_REDEEM_ERROR',
        error,
        traceId,
        stopwatch.elapsedMilliseconds,
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  void _traceDioError(
    String event,
    DioException error,
    String fallbackRid,
    int elapsedMs,
  ) {
    final String rid = _requestId(error.response, fallbackRid);
    _trace(
      event,
      'rid=$rid status=${error.response?.statusCode} dioType=${error.type} '
      'elapsedMs=$elapsedMs shape=${_bodyShape(error.response?.data)} '
      'body=${_safeBody(error.response?.data)}',
    );
  }

  String _requestId(Response<dynamic>? response, String fallback) {
    if (response == null) return fallback;
    final dynamic data = response.data;
    if (data is Map) {
      final String value =
          (data['requestId'] ?? data['request_id'])?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    final String value =
        response.headers.value('X-Request-Id')?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _bodyShape(dynamic data) {
    if (data == null) return 'null';
    if (data is Map) return 'map(keys=${data.keys.length})';
    if (data is List) return 'list(length=${data.length})';
    if (data is String) return 'string(length=${data.length})';
    return data.runtimeType.toString();
  }

  String _safeBody(dynamic data) {
    if (data == null) return 'null';
    String raw;
    try {
      raw = data is String ? data : jsonEncode(data);
    } catch (_) {
      raw = data.toString();
    }
    final String safe = sanitizeLogMessage(raw).replaceAll(RegExp(r'\s+'), ' ');
    return safe.length <= 700 ? safe : '${safe.substring(0, 700)}...[truncated]';
  }

  void _trace(String event, String details) {
    dlog('[P0_DIAG][IDP_FLUTTER][$event] $details', wrapWidth: 1000);
  }

  void _traceStack(StackTrace stackTrace) {
    final String compact = stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .join(' | ');
    dlog('[P0_DIAG][IDP_FLUTTER][STACK] $compact', wrapWidth: 1000);
  }
}
