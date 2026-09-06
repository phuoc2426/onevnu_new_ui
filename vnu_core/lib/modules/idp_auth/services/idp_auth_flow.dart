import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/session_logout_gate.dart';
import 'package:vnu_core/modules/idp_auth/repository/idp_auth_repository.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_device_binding_service.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_onevnu_session_service.dart';
import 'package:vnu_core/modules/idp_auth/views/idp_login_webview.dart';
import 'package:vnu_core/services/app_config_service.dart';

class IdpAuthFlow {
  IdpAuthFlow._internal();

  static final IdpAuthFlow _instance = IdpAuthFlow._internal();

  factory IdpAuthFlow() => _instance;

  /// Opens the VNU IDP authorization URL inside the ONEVNU WebView.
  /// Backend still owns state + nonce + PKCE verifier + code exchange + IDP tokens.
  /// Flutter only keeps the per-login possession secret in memory.
  Future<bool> login(
    BuildContext context, {
    bool forceLogin = false,
    String? flowId,
  }) async {
    final String effectiveFlowId =
        (flowId != null && flowId.trim().isNotEmpty)
            ? flowId.trim()
            : const Uuid().v4();
    final Stopwatch total = Stopwatch()..start();
    _trace('FLOW_BEGIN', 'flowId=$effectiveFlowId forceLogin=$forceLogin');

    try {
      await SessionLogoutGate.waitForCriticalLogout();
      final Stopwatch configWatch = Stopwatch()..start();
      final AppConfigService configService = AppConfigService();
      await configService.ensureLoaded(forceRefresh: true);
      _trace(
        'CONFIG_DONE',
        'forceLogin=$forceLogin elapsedMs=${configWatch.elapsedMilliseconds} '
        'loaded=${configService.isLoadedSuccessfully} '
        'idpLogin=${configService.loginRuntimeConfig.idpLogin}',
      );
      if (!configService.isLoadedSuccessfully ||
          !configService.loginRuntimeConfig.idpLogin) {
        throw StateError(
          configService.lastLoadError ?? 'VNU IDP hiện không khả dụng.',
        );
      }

      final Stopwatch bindingWatch = Stopwatch()..start();
      final IdpLoginBinding binding =
          await IdpDeviceBindingService().createLoginBinding();
      _trace(
        'BINDING_DONE',
        'elapsedMs=${bindingWatch.elapsedMilliseconds} '
        'deviceIdLength=${binding.deviceId.length} '
        'challengeLength=${binding.challenge.length} '
        'secretLength=${binding.secret.length}',
      );

      // IMPORTANT: never open /api/auth/idp/mobile/start directly.
      final Stopwatch initWatch = Stopwatch()..start();
      final Uri authorizationUri = await IdpAuthRepository().initLogin(
        deviceId: binding.deviceId,
        bindingChallenge: binding.challenge,
        forceLogin: forceLogin,
        flowId: effectiveFlowId,
      );
      _trace(
        'INIT_DONE',
        'elapsedMs=${initWatch.elapsedMilliseconds} '
        'host=${authorizationUri.host} path=${authorizationUri.path}',
      );

      final Stopwatch webViewWatch = Stopwatch()..start();
      _trace(
        'WEBVIEW_OPEN',
        'host=${authorizationUri.host} forceLogin=$forceLogin',
      );
      final IdpWebLoginResult? callback =
          await Navigator.of(context).push<IdpWebLoginResult>(
        MaterialPageRoute<IdpWebLoginResult>(
          builder: (_) => IdpLoginWebView(
            startUri: authorizationUri,
            forceCloseWebViewOnBack: false,
          ),
        ),
      );
      _trace(
        'WEBVIEW_CLOSED',
        'elapsedMs=${webViewWatch.elapsedMilliseconds} '
        'result=${callback == null ? "cancelled" : callback.isSuccess ? "success" : "failure"} '
        'ticketLength=${callback?.ticket?.length ?? 0} '
        'errorLength=${callback?.error?.length ?? 0}',
      );

      if (callback == null) {
        _trace('FLOW_CANCELLED', 'totalMs=${total.elapsedMilliseconds}');
        return false;
      }
      if (!callback.isSuccess) {
        throw StateError(
          callback.error ?? 'Đăng nhập VNU IDP không thành công.',
        );
      }

      final Stopwatch redeemWatch = Stopwatch()..start();
      if (forceLogin) {
        await IdpAuthRepository().redeemReauthTicket(
          ticket: callback.ticket!,
          bindingSecret: binding.secret,
          deviceId: binding.deviceId,
          flowId: effectiveFlowId,
        );
        _trace(
          'REAUTH_REDEEM_DONE',
          'elapsedMs=${redeemWatch.elapsedMilliseconds} '
          'totalMs=${total.elapsedMilliseconds}',
        );
        return true;
      }

      final response = await IdpAuthRepository().redeemTicket(
        ticket: callback.ticket!,
        bindingSecret: binding.secret,
        deviceId: binding.deviceId,
        flowId: effectiveFlowId,
      );
      _trace(
        'REDEEM_DONE',
        'elapsedMs=${redeemWatch.elapsedMilliseconds}',
      );

      final Stopwatch sessionWatch = Stopwatch()..start();
      await IdpOneVnuSessionService().apply(response);
      _trace(
        'SESSION_APPLIED',
        'elapsedMs=${sessionWatch.elapsedMilliseconds} '
        'totalMs=${total.elapsedMilliseconds}',
      );
      return true;
    } catch (error, stackTrace) {
      _trace(
        'FLOW_ERROR',
        'flowId=$effectiveFlowId forceLogin=$forceLogin type=${error.runtimeType} message=$error '
        'totalMs=${total.elapsedMilliseconds}',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  void _trace(String event, String details) {
    dlog('[P0_DIAG][IDP_FLOW][$event] $details', wrapWidth: 1000);
  }

  void _traceStack(StackTrace stackTrace) {
    final String compact = stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .join(' | ');
    dlog('[P0_DIAG][IDP_FLOW][STACK] $compact', wrapWidth: 1000);
  }
}
