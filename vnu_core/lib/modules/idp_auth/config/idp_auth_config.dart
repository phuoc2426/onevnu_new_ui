/// Constants that belong to the app-side callback protocol only.
///
/// IDP hosts and start URLs are runtime configuration from GET /api/config.
/// Do not add compile-time IDP/admin URLs back here: that would allow Flutter
/// to disagree with the server's current login mode.
class IdpAuthConfig {
  const IdpAuthConfig._();

  static const String callbackScheme = 'onevnu';
  static const String callbackHost = 'idp';
  static const String callbackPath = '/callback';

  static bool isAppCallback(Uri uri) {
    return uri.scheme == callbackScheme &&
        uri.host == callbackHost &&
        uri.path == callbackPath;
  }
}
