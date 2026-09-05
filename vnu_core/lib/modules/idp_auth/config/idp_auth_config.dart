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

  /// TEMP ONLY - ép màn đăng nhập mở thẳng IDP test để kiểm tra UI.
  ///
  /// ĐỂ QUAY VỀ LUỒNG API BAN ĐẦU: chỉ comment đúng dòng gán URL bên dưới.
  /// Khi dòng đó bị comment, getter trả null; Login V3/V4 và IdpAuthFlow
  /// sẽ lại lấy phương thức + idpStartUrl từ GET /api/config.
  static String? get temporaryTestStartUrl {
    String? url;
    // url = 'https://idp.vnu.edu.vn'; // TEMP TEST: COMMENT DÒNG NÀY ĐỂ VỀ API
    return url;
  }

  static bool get temporaryTestEnabled {
    final String value = temporaryTestStartUrl?.trim() ?? '';
    return value.isNotEmpty;
  }

  static bool isAppCallback(Uri uri) {
    return uri.scheme == callbackScheme &&
        uri.host == callbackHost &&
        uri.path == callbackPath;
  }
}
