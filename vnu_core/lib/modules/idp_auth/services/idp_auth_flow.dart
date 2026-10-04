import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/session_logout_gate.dart';
import 'package:vnu_core/modules/auth_mode/login_config_resolver.dart';
import 'package:vnu_core/modules/auth_mode/login_runtime_config.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';
import 'package:vnu_core/modules/idp_auth/repository/idp_auth_repository.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_auth_callback_service.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_device_binding_service.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_onevnu_session_service.dart';
import 'package:vnu_core/modules/idp_auth/views/idp_login_webview.dart';

enum IdpBrowserMode {
  /// Original ONEVNU flow from the 2026-09-11 source.
  webView,

  /// Android Custom Tabs / iOS in-app browser view through url_launcher.
  customTab,

  /// External/default system browser.
  systemBrowser,
}

extension IdpBrowserModeLabel on IdpBrowserMode {
  String get label => switch (this) {
        IdpBrowserMode.webView => 'WebView',
        IdpBrowserMode.customTab => 'Custom Tab',
        IdpBrowserMode.systemBrowser => 'Trình duyệt',
      };
}

class IdpAuthFlow {
  IdpAuthFlow._internal();

  static final IdpAuthFlow _instance = IdpAuthFlow._internal();

  factory IdpAuthFlow() => _instance;

  /// Default transport is the external system browser on both Android and iOS.
  /// This keeps the VNU SSO flow in Chrome/Safari and avoids platform-specific
  /// behavior from embedded browser containers. WebView/Custom Tab remain only
  /// for explicit internal compatibility callers.
  Future<bool> login(
    BuildContext context, {
    bool forceLogin = false,
    String? flowId,
    IdpBrowserMode browserMode = IdpBrowserMode.systemBrowser,
    bool skipConfigGate = false,
  }) async {
    final String effectiveFlowId =
        (flowId != null && flowId.trim().isNotEmpty)
            ? flowId.trim()
            : const Uuid().v4();
    final Stopwatch total = Stopwatch()..start();
    _trace(
      'FLOW_BEGIN',
      'flowId=$effectiveFlowId forceLogin=$forceLogin browserMode=${browserMode.name}',
    );

    try {
      await SessionLogoutGate.waitForCriticalLogout();

      if (!skipConfigGate) {
        _trace(
          'CONFIG_RESOLVE_BEGIN',
          'source=${IdpAuthConfig.loginConfigSourceLabel}',
        );
        final LoginRuntimeConfig loginConfig =
            await LoginConfigResolver().resolve(forceRefresh: true);
        _trace(
          'CONFIG_DONE',
          'source=${IdpAuthConfig.useStaticLoginConfig ? "STATIC" : "API"} '
          'idpLogin=${loginConfig.idpLogin} qrEnabled=${loginConfig.qrEnabled}',
        );
        if (!loginConfig.idpLogin) {
          throw StateError('VNU IDP hiện không khả dụng.');
        }
      } else {
        _trace(
          'CONFIG_GATE_SKIPPED',
          'callerAlreadyResolved=true source=${IdpAuthConfig.loginConfigSourceLabel}',
        );
      }

      final Stopwatch bindingWatch = Stopwatch()..start();
      _trace('BINDING_BEGIN', 'flowId=$effectiveFlowId');
      final IdpLoginBinding binding =
          await IdpDeviceBindingService().createLoginBinding();
      _trace(
        'BINDING_DONE',
        'elapsedMs=${bindingWatch.elapsedMilliseconds} '
        'deviceIdLength=${binding.deviceId.length} '
        'challengeLength=${binding.challenge.length}',
      );

      // IMPORTANT: never open /api/auth/idp/mobile/start directly.
      final Stopwatch initWatch = Stopwatch()..start();
      _trace(
        'INIT_BEGIN',
        'flowId=$effectiveFlowId endpoint=/api/auth/idp/init',
      );
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

      final _CallbackOutcome callback = await _openAuthorization(
        context,
        authorizationUri,
        browserMode: browserMode,
        forceLogin: forceLogin,
      );

      if (callback.cancelled) {
        _trace('FLOW_CANCELLED', 'totalMs=${total.elapsedMilliseconds}');
        return false;
      }
      if (!callback.isSuccess) {
        throw StateError(
          callback.error ?? 'Đăng nhập VNU IDP không thành công.',
        );
      }

      _sessionTrace(
        'CALLBACK_OK',
        'flowId=$effectiveFlowId forceLogin=$forceLogin '
        'browserMode=${browserMode.name} ticketPresent=true',
      );

      final Stopwatch redeemWatch = Stopwatch()..start();
      _trace(
        forceLogin ? 'REAUTH_REDEEM_BEGIN' : 'REDEEM_BEGIN',
        'flowId=$effectiveFlowId',
      );
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
        _sessionTrace(
          'REAUTH_REDEEM_OK',
          'flowId=$effectiveFlowId elapsedMs=${redeemWatch.elapsedMilliseconds}',
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
      _sessionTrace(
        'ONEVNU_REDEEM_OK',
        'flowId=$effectiveFlowId elapsedMs=${redeemWatch.elapsedMilliseconds}',
      );

      final Stopwatch sessionWatch = Stopwatch()..start();
      await IdpOneVnuSessionService().apply(response);
      _trace(
        'SESSION_APPLIED',
        'elapsedMs=${sessionWatch.elapsedMilliseconds} '
        'totalMs=${total.elapsedMilliseconds}',
      );
      _sessionTrace(
        'ONEVNU_SESSION_READY',
        'flowId=$effectiveFlowId totalMs=${total.elapsedMilliseconds}',
      );
      return true;
    } catch (error, stackTrace) {
      _trace(
        'FLOW_ERROR',
        'flowId=$effectiveFlowId forceLogin=$forceLogin '
        'browserMode=${browserMode.name} type=${error.runtimeType} message=$error '
        'totalMs=${total.elapsedMilliseconds}',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  Future<_CallbackOutcome> _openAuthorization(
    BuildContext context,
    Uri authorizationUri, {
    required IdpBrowserMode browserMode,
    required bool forceLogin,
  }) async {
    if (browserMode == IdpBrowserMode.webView) {
      // EXACT original transport: Navigator -> IdpLoginWebView -> result.
      final Stopwatch watch = Stopwatch()..start();
      _trace(
        'WEBVIEW_OPEN',
        'host=${authorizationUri.host} forceLogin=$forceLogin',
      );
      final IdpWebLoginResult? result =
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
        'elapsedMs=${watch.elapsedMilliseconds} '
        'result=${result == null ? "cancelled" : result.isSuccess ? "success" : "failure"}',
      );
      if (result == null) return const _CallbackOutcome.cancelled();
      return result.isSuccess
          ? _CallbackOutcome.success(result.ticket!)
          : _CallbackOutcome.failure(
              result.error ?? 'Đăng nhập VNU IDP không thành công.',
            );
    }

    final IdpAuthCallbackService callbackService = IdpAuthCallbackService();
    callbackService.prepareNewLogin();

    final LaunchMode launchMode = browserMode == IdpBrowserMode.customTab
        ? LaunchMode.inAppBrowserView
        : LaunchMode.externalApplication;
    final String eventPrefix = browserMode == IdpBrowserMode.customTab
        ? 'CUSTOM_TAB'
        : 'SYSTEM_BROWSER';

    _trace(
      '${eventPrefix}_OPEN',
      'host=${authorizationUri.host} forceLogin=$forceLogin',
    );
    final bool opened = await launchUrl(
      authorizationUri,
      mode: launchMode,
    );
    _trace('${eventPrefix}_OPENED', 'opened=$opened');
    if (!opened) {
      throw StateError(
        browserMode == IdpBrowserMode.customTab
            ? 'Không thể mở VNU IDP bằng Custom Tab.'
            : 'Không thể mở VNU IDP bằng trình duyệt hệ thống.',
      );
    }

    final Stopwatch callbackWatch = Stopwatch()..start();
    final IdpAuthCallbackResult result =
        await callbackService.waitForCallback();
    _trace(
      '${eventPrefix}_CALLBACK',
      'elapsedMs=${callbackWatch.elapsedMilliseconds} success=${result.isSuccess}',
    );
    return result.isSuccess
        ? _CallbackOutcome.success(result.ticket!)
        : _CallbackOutcome.failure(
            result.error ?? 'Đăng nhập VNU IDP không thành công.',
          );
  }

  void _trace(String event, String details) {
    dlog('[P0_DIAG][IDP_FLOW][$event] $details', wrapWidth: 1000);
  }

  void _sessionTrace(String event, String details) {
    dlog('[P1B_SESSION][FLUTTER][$event] $details', wrapWidth: 1000);
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

class _CallbackOutcome {
  const _CallbackOutcome._({this.ticket, this.error, this.cancelled = false});

  const _CallbackOutcome.success(String ticket)
      : this._(ticket: ticket);

  const _CallbackOutcome.failure(String error)
      : this._(error: error);

  const _CallbackOutcome.cancelled()
      : this._(cancelled: true);

  final String? ticket;
  final String? error;
  final bool cancelled;

  bool get isSuccess => (ticket ?? '').isNotEmpty;
}
