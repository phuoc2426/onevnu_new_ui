/// App-side constants for the ONEVNU IDP callback protocol.
///
/// The OAuth redirect_uri remains the BACKEND callback. The final redirect from
/// backend -> app carries only a one-time ONEVNU login ticket.
///
/// P0 WebView mode accepts both:
/// - onevnu://idp/callback            (current server runtime)
/// - https://onevnu-admin.vnu.edu.vn/idp/callback (verified HTTPS transition)
class IdpAuthConfig {
  const IdpAuthConfig._();

  static const String callbackScheme = 'https';
  static const String callbackHost = 'onevnu-admin.vnu.edu.vn';
  static const String callbackPath = '/idp/callback';

  static const String webViewCallbackScheme = 'onevnu';
  static const String webViewCallbackHost = 'idp';
  static const String webViewCallbackPath = '/callback';

  static const Duration callbackTimeout = Duration(minutes: 6);

  /// TEMP TEST hook kept disabled. Runtime IDP mode still comes from /api/config.
  ///
  /// IMPORTANT: never set this to /api/auth/idp/mobile/start in P0 because that
  /// endpoint requires deviceId + bindingChallenge. Production login must first
  /// call POST /api/auth/idp/init through IdpAuthRepository.
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

    final bool currentWebViewCallback =
        scheme == webViewCallbackScheme &&
        host == webViewCallbackHost &&
        uri.path == webViewCallbackPath;

    final bool verifiedHttpsCallback =
        scheme == callbackScheme &&
        host == callbackHost &&
        uri.path == callbackPath;

    return currentWebViewCallback || verifiedHttpsCallback;
  }
}
