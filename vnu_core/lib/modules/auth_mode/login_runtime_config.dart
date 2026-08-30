class LoginRuntimeConfig {
  const LoginRuntimeConfig({
    required this.idpLogin,
    required this.idpStartUrl,
    required this.idpWebUrl,
    required this.passwordFallbackEnabled,
    required this.qrEnabled,
  });

  static const LoginRuntimeConfig defaults = LoginRuntimeConfig(
    idpLogin: false,
    idpStartUrl: '',
    idpWebUrl: '',
    passwordFallbackEnabled: true,
    qrEnabled: false,
  );

  final bool idpLogin;
  final String idpStartUrl;
  final String idpWebUrl;
  final bool passwordFallbackEnabled;
  final bool qrEnabled;

  bool get isIdpOnly => idpLogin;

  factory LoginRuntimeConfig.fromAppConfig(Map<String, dynamic> config) {
    final Map<String, dynamic> root = _unwrapConfig(config);
    final Map<String, dynamic> login = root['login'] is Map
        ? Map<String, dynamic>.from(root['login'] as Map)
        : const <String, dynamic>{};

    dynamic readRaw(List<String> keys) {
      for (final String key in keys) {
        if (login.containsKey(key) && login[key] != null) {
          return login[key];
        }
      }
      for (final String key in keys) {
        if (root.containsKey(key) && root[key] != null) {
          return root[key];
        }
      }
      return null;
    }

    bool readBool(List<String> keys, {required bool fallback}) {
      final dynamic raw = readRaw(keys);
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;

      final String value = raw?.toString().trim().toLowerCase() ?? '';
      if (const <String>{'true', '1', 'yes', 'on', 'enabled'}.contains(value)) {
        return true;
      }
      if (const <String>{'false', '0', 'no', 'off', 'disabled'}.contains(value)) {
        return false;
      }
      return fallback;
    }

    String readUrl(List<String> keys) {
      final String value = readRaw(keys)?.toString().trim() ?? '';
      if (value.isEmpty) return '';

      final Uri? uri = Uri.tryParse(value);
      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        return '';
      }
      return value;
    }

    final bool requestedIdpLogin = readBool(
      const <String>[
        'idpLogin',
        'idp_login',
        'idpEnabled',
        'idp_enabled',
      ],
      fallback: false,
    );

    final String idpStartUrl = readUrl(
      const <String>[
        'idpStartUrl',
        'idpLoginUrl',
        'idp_login_url',
        'startUrl',
      ],
    );

    // Fail safe: IDP mode is active only when the server explicitly enables
    // it AND provides a valid HTTP(S) start URL. Flutter never falls back to a
    // compile-time IDP URL.
    final bool effectiveIdpLogin =
        requestedIdpLogin && idpStartUrl.isNotEmpty;

    final bool requestedQrEnabled = readBool(
      const <String>[
        'qrEnabled',
        'idpQrEnabled',
        'idp_qr_enabled',
      ],
      fallback: true,
    );

    return LoginRuntimeConfig(
      idpLogin: effectiveIdpLogin,
      idpStartUrl: idpStartUrl,
      idpWebUrl: readUrl(
        const <String>[
          'idpWebUrl',
          'idpWebBaseUrl',
          'idp_web_url',
        ],
      ),
      passwordFallbackEnabled: readBool(
        const <String>[
          'passwordFallbackEnabled',
          'idpPasswordFallbackEnabled',
          'idp_password_fallback_enabled',
        ],
        fallback: true,
      ),
      qrEnabled: effectiveIdpLogin && requestedQrEnabled,
    );
  }

  static Map<String, dynamic> _unwrapConfig(Map<String, dynamic> input) {
    Map<String, dynamic> current = Map<String, dynamic>.from(input);

    // Be tolerant when /api/config is later wrapped by a common API envelope.
    // Current production response is already a direct object, so this has no
    // effect on today's contract.
    for (int i = 0; i < 2; i++) {
      final dynamic nested = current['data'] ?? current['result'];
      if (nested is! Map) break;

      final Map<String, dynamic> candidate =
          Map<String, dynamic>.from(nested);
      final bool looksLikeConfig = candidate.containsKey('login') ||
          candidate.containsKey('ktxApiUrl') ||
          candidate.containsKey('vneidApiUrl') ||
          candidate.containsKey('appUpdate');
      if (!looksLikeConfig) break;

      current = candidate;
    }

    return current;
  }
}
