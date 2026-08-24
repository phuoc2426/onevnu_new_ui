class IdpAuthConfig {
  const IdpAuthConfig._();

  /// Cổng IdP mà người dùng nhìn thấy trong WebView.
  static const String idpWebBaseUrl = String.fromEnvironment(
    'ONEVNU_IDP_WEB_URL',
    defaultValue: 'https://idp-test.vnu.edu.vn',
  );

  /// API web/admin giữ callback OIDC từ IdP.
  /// Có thể override khi chạy test:
  /// flutter run --dart-define=ONEVNU_ADMIN_API_URL=https://...
  static const String adminApiBaseUrl = String.fromEnvironment(
    'ONEVNU_ADMIN_API_URL',
    defaultValue: 'https://onevnu-admin.vnu.edu.vn',
  );

  static const String startPath = '/api/auth/idp/mobile/start';

  /// Backend callback cuối cùng redirect về URI này.
  /// URI được WebView chặn bên trong app, không đưa IdP token vào URL.
  static const String callbackScheme = 'onevnu';
  static const String callbackHost = 'idp';
  static const String callbackPath = '/callback';

  static Uri buildStartUri() {
    final String base = adminApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$startPath');
  }

  static bool isAppCallback(Uri uri) {
    return uri.scheme == callbackScheme &&
        uri.host == callbackHost &&
        uri.path == callbackPath;
  }
}
