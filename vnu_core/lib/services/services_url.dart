import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ServicesUrl {
  static const String defaultBaseUrl = 'https://onevnu-mobile-api.vnu.edu.vn';
  // static const String defaultBaseUrl = 'http://112.137.132.211:8082';
  static const String defaultZaloGroupUrl =
      'https://zalo.me/g/3cu4aftrlhlomcnjm8vx';

  static const String _legacyDomainKey = 'domain';
  static const String _downloadDomainKey = 'domainFileDownload';
  static const String _ktxApiUrlKey = 'ktx_api_url';
  static const String _vneidApiUrlKey = 'vneid_api_url';
  static const String _cccdConfigApiUrlKey = 'cccd_config_api_url';
  static const String _zaloGroupUrlKey = 'zalo_group_url';

  static final ServicesUrl _singleton = ServicesUrl._internal();

  factory ServicesUrl() {
    return _singleton;
  }

  ServicesUrl._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> init() {
    if (_initialized) {
      return Future<void>.value();
    }

    final Future<void>? current = _initializing;
    if (current != null) {
      return current;
    }

    final Future<void> request = _initialize();
    _initializing = request;

    return request.whenComplete(() {
      if (identical(_initializing, request)) {
        _initializing = null;
      }
    });
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // The ONEVNU mobile API is fixed. Remove any domain selected or cached by
    // older app versions so it can never redirect core requests to an old API.
    await _prefs.remove(_legacyDomainKey);

    _initialized = true;
  }

  bool get isInitialized => _initialized;

  String? get firebaseToken =>
      _initialized ? _prefs.getString('firebase_token') : null;

  set firebaseToken(String? token) {
    if (!_initialized) return;
    _prefs.setString('firebase_token', token ?? '');
  }

  /// Core ONEVNU API. This URL is intentionally fixed and is never read from
  /// SharedPreferences or remote config.
  String get baseUrl => '$defaultBaseUrl/';

  String get baseUrlFileDownload {
    final String configured = _getPrefString(_downloadDomainKey);
    final String domain = configured.isNotEmpty ? configured : baseUrl;
    return '${domain.endsWith('/') ? domain : '$domain/'}api/file/download/';
  }

  String get baseUrlImage {
    final String configured = _getPrefString(_downloadDomainKey);
    return configured.isNotEmpty ? configured : baseUrl;
  }

  String _getPrefString(String key) {
    if (!_initialized) return '';
    return _prefs.getString(key) ?? '';
  }

  String get ktxApiUrl => _getPrefString(_ktxApiUrlKey);

  String get vneidApiUrl => _getPrefString(_vneidApiUrlKey);

  String get cccdConfigApiUrl => _getPrefString(_cccdConfigApiUrlKey);

  String get zaloGroupUrl => _getPrefString(_zaloGroupUrlKey);

  String get effectiveZaloGroupUrl {
    final String configured = zaloGroupUrl.trim();
    return configured.isNotEmpty ? configured : defaultZaloGroupUrl;
  }

  set zaloGroupUrl(String url) {
    if (!_initialized) return;
    _prefs.setString(_zaloGroupUrlKey, url.trim());
  }

  String get effectiveKtxApiUrl {
    final String url = ktxApiUrl.trim();
    return url.isNotEmpty ? (url.endsWith('/') ? url : '$url/') : '';
  }

  String get effectiveKtxDormitoryApiUrl {
    final String url = effectiveKtxApiUrl;
    if (url.isEmpty) return '';
    return url.endsWith('/dormitory/') ? url : '${url}dormitory/';
  }

  String get effectiveKtxHostUrl {
    final String url = ktxApiUrl.trim();
    if (url.isEmpty) return '';

    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return '';

    final String host =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    return host.endsWith('/') ? host : '$host/';
  }

  String get effectiveVneidApiUrl {
    final String url = vneidApiUrl.trim();
    return url.isNotEmpty ? (url.endsWith('/') ? url : '$url/') : '';
  }

  String get effectiveCccdConfigApiUrl {
    final String url = cccdConfigApiUrl.trim();
    return url.isNotEmpty ? (url.endsWith('/') ? url : '$url/') : '';
  }

  set baseUrlFileDownload(String? domain) {
    if (!_initialized) return;

    final String normalized = domain?.trim() ?? '';
    if (normalized.isEmpty) {
      _prefs.remove(_downloadDomainKey);
    } else {
      _prefs.setString(_downloadDomainKey, normalized);
    }
  }

  /// Kept only for backward compatibility. Core API domain switching is
  /// disabled; any legacy value is removed instead of being applied.
  set baseUrl(String _) {
    if (!_initialized) return;
    _prefs.remove(_legacyDomainKey);
  }

  set ktxApiUrl(String url) {
    if (!_initialized) return;
    _prefs.setString(_ktxApiUrlKey, url.trim());
  }

  set vneidApiUrl(String url) {
    if (!_initialized) return;
    _prefs.setString(_vneidApiUrlKey, url.trim());
  }

  set cccdConfigApiUrl(String url) {
    if (!_initialized) return;
    _prefs.setString(_cccdConfigApiUrlKey, url.trim());
  }

  /// Clears values owned by /api/config. Call this before a remote refresh so
  /// a failed refresh cannot silently reuse an obsolete API URL.
  void clearRemoteConfig() {
    if (!_initialized) return;

    _prefs.remove(_downloadDomainKey);
    _prefs.setString(_ktxApiUrlKey, '');
    _prefs.setString(_vneidApiUrlKey, '');
    _prefs.setString(_cccdConfigApiUrlKey, '');
    _prefs.setString(_zaloGroupUrlKey, '');
  }

  set topics(List<String> topics) {
    if (!_initialized) return;
    _prefs.setString('topics', jsonEncode(topics));
  }

  List<String> get topics {
    if (!_initialized) return <String>[];

    final String? value = _prefs.getString('topics');
    if (value == null || value.isEmpty) {
      return <String>[];
    }

    try {
      return json.decode(value).cast<String>();
    } catch (_) {
      return <String>[];
    }
  }

  final String authenticate = 'api/auth/signin';
}
