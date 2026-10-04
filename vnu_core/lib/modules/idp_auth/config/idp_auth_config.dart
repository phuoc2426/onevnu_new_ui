import 'package:vnu_core/modules/auth_mode/login_runtime_config.dart';

/// ONEVNU IDP client-side configuration.
///
/// [useStaticLoginConfig] controls ONLY the source of the login-mode config:
/// - true  -> use [staticLoginRuntimeConfig] and DO NOT let /api/config disable
///            the IDP login test flow.
/// - false -> use GET /api/config as the source of truth.
///
/// This flag does NOT choose WebView / Custom Tab / System Browser.
class IdpAuthConfig {
  const IdpAuthConfig._();

  /// Normal builds use GET /api/config as the source of truth so optional
  /// login methods can be enabled/hidden without rebuilding the application.
  /// Static mode remains available only when explicitly enabled for diagnosis.
  static const bool useStaticLoginConfig = bool.fromEnvironment(
    'ONEVNU_USE_STATIC_LOGIN_CONFIG',
    defaultValue: false,
  );

  // Compatibility alias for older call sites/patches.
  static const bool useStaticConfig = useStaticLoginConfig;

  /// Compatibility flag retained for older call sites. V4 no longer uses it
  /// to expose or automatically select password login.
  static const bool alwaysShowPasswordLogin = bool.fromEnvironment(
    'ONEVNU_ALWAYS_SHOW_PASSWORD_LOGIN',
    defaultValue: false,
  );

  static const bool staticIdpLogin = true;
  static const String staticIdpStartUrl =
      'https://onevnu-admin.vnu.edu.vn/api/auth/idp/mobile/start';
  static const String staticIdpWebUrl = 'https://idp.vnu.edu.vn/';

  /// QR stays disabled in static diagnostic mode because the backend QR API is
  /// intentionally still governed by the server-side `idp_login` switch.
  static const bool staticQrEnabled = false;
  static const bool staticPasswordFallbackEnabled = false;

  static const LoginRuntimeConfig staticLoginRuntimeConfig = LoginRuntimeConfig(
    idpLogin: staticIdpLogin,
    idpStartUrl: staticIdpStartUrl,
    idpWebUrl: staticIdpWebUrl,
    studentCodeLoginEnabled: false,
    cccdLoginEnabled: false,
    applicantLoginEnabled: false,
    passwordFallbackEnabled: staticPasswordFallbackEnabled,
    qrEnabled: staticQrEnabled,
  );

  /// Browser selection is intentionally hidden from end users. The login screen
  /// opens VNU SSO through Custom Tab only. Kept for source compatibility.
  static const bool showBrowserModeSelector = false;

  static String get loginConfigSourceLabel =>
      useStaticLoginConfig ? 'STATIC' : 'API';

  // OAuth redirect remains backend-owned. These values are only for the final
  // backend -> app callback handling.
  static const String callbackScheme = 'https';
  static const String callbackHost = 'onevnu-admin.vnu.edu.vn';
  static const String callbackPath = '/idp/callback';

  // Current production backend app callback:
  // -Dapplication.idp.app-callback-uri=onevnu://idp/callback
  static const String webViewCallbackScheme = 'onevnu';
  static const String webViewCallbackHost = 'idp';
  static const String webViewCallbackPath = '/callback';

  static const Duration callbackTimeout = Duration(minutes: 6);

  /// Legacy temporary hook intentionally disabled. The secure mobile flow must
  /// create device binding and call POST /api/auth/idp/init first.
  static String? get temporaryTestStartUrl {
    String? url;
    return url;
  }

  static bool get temporaryTestEnabled {
    final String value = temporaryTestStartUrl?.trim() ?? '';
    return value.isNotEmpty;
  }

  static bool isAppCallback(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();
    final String host = uri.host.toLowerCase();

    final bool customSchemeCallback =
        scheme == webViewCallbackScheme &&
        host == webViewCallbackHost &&
        uri.path == webViewCallbackPath;

    final bool verifiedHttpsCallback =
        scheme == callbackScheme &&
        host == callbackHost &&
        uri.path == callbackPath;

    return customSchemeCallback || verifiedHttpsCallback;
  }
}
