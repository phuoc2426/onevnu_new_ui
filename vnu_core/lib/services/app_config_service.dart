import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/services/services_url.dart';

import 'app_update_policy.dart';
import '../modules/auth_mode/login_runtime_config.dart';

/// Loads /api/config from the fixed ONEVNU mobile API.
///
/// Important P4.2 invariants:
/// - Login mode is read from the server at runtime; Flutter has no IDP URL
///   fallback compiled into the app.
/// - /api/config is bootstrap/public configuration and is fetched with a clean
///   Dio instance, without the normal authenticated API interceptor.
/// - A KTX/VNeID/Zalo configuration problem must never silently turn IDP off.
/// - If the bootstrap request itself fails, callers can inspect [lastLoadError]
///   and show an explicit password-fallback notice instead of pretending that
///   the server configured password mode.
class AppConfigService {
  static const Duration _failureRetryDelay = Duration(minutes: 1);

  static final AppConfigService _singleton = AppConfigService._internal();

  factory AppConfigService() => _singleton;

  AppConfigService._internal();

  final ValueNotifier<String> zaloGroupUrlNotifier =
      ValueNotifier<String>(ServicesUrl.defaultZaloGroupUrl);

  Future<void>? _inFlight;
  DateTime? _lastRemoteAttemptAt;
  bool _loadedSuccessfully = false;
  String? _lastLoadError;
  AppUpdatePolicy? _appUpdatePolicy;
  LoginRuntimeConfig _loginRuntimeConfig = LoginRuntimeConfig.defaults;

  bool get isLoadedSuccessfully => _loadedSuccessfully;

  String? get lastLoadError => _lastLoadError;

  bool get hasLoadError => (_lastLoadError ?? '').trim().isNotEmpty;

  AppUpdatePolicy? get appUpdatePolicy => _appUpdatePolicy;

  LoginRuntimeConfig get loginRuntimeConfig => _loginRuntimeConfig;

  bool get hasEnabledAppUpdatePolicy =>
      _appUpdatePolicy?.android.isConfigured == true ||
      _appUpdatePolicy?.ios.isConfigured == true;

  String get effectiveZaloGroupUrl {
    final String current = zaloGroupUrlNotifier.value.trim();
    if (current.isNotEmpty) {
      return current;
    }
    return ServicesUrl().effectiveZaloGroupUrl;
  }

  /// Fetch only the login-method section from /api/config.
  ///
  /// This is intentionally independent from the full app-config hydration.
  /// The login button uses it as a last-second source of truth so an unrelated
  /// KTX/VNeID/update config parsing problem can never leave the UI on a stale
  /// authentication method. This call never falls back to the cached method: if
  /// the network/config request fails, the caller must stop the login attempt.
  Future<LoginRuntimeConfig> fetchLatestLoginRuntimeConfig() async {
    await ServicesUrl().init();
    final Map<String, dynamic> config = await _fetchRemoteConfig();
    final LoginRuntimeConfig latest = LoginRuntimeConfig.fromAppConfig(config);

    // Keep the singleton's login snapshot aligned with the value that was
    // explicitly verified, without marking the entire app config as loaded.
    _loginRuntimeConfig = latest;
    _lastLoadError = null;

    logInfo(
      '[LOGIN_CONFIG_DIRECT] idpLogin=${latest.idpLogin} '
      'qrEnabled=${latest.qrEnabled} '
      'idpStartUrl=${latest.idpStartUrl.isEmpty ? "<empty>" : latest.idpStartUrl}',
    );
    return latest;
  }

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    await ServicesUrl().init();

    if (!forceRefresh && _loadedSuccessfully) {
      return;
    }

    final Future<void>? current = _inFlight;
    if (current != null) {
      await current;
      return;
    }

    final DateTime? lastAttempt = _lastRemoteAttemptAt;
    if (!forceRefresh &&
        lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < _failureRetryDelay) {
      return;
    }

    _lastRemoteAttemptAt = DateTime.now();

    // Do not clear the last known-good config before a refresh. A refresh may
    // run while the login screen is visible; clearing first would temporarily
    // switch KTX/IDP/CCCD endpoints to defaults and could affect concurrent
    // requests. New values replace the old values atomically after success.
    final Future<void> request = _loadRemoteConfig();
    _inFlight = request;

    try {
      await request;
    } finally {
      if (identical(_inFlight, request)) {
        _inFlight = null;
      }
    }
  }

  Future<void> _loadRemoteConfig() async {
    final bool hadUsableConfig = _loadedSuccessfully;
    final LoginRuntimeConfig previousLoginConfig = _loginRuntimeConfig;
    final AppUpdatePolicy? previousUpdatePolicy = _appUpdatePolicy;

    try {
      final Map<String, dynamic> config = await _fetchRemoteConfig();

      // LOGIN IS PARSED FIRST AND INDEPENDENTLY.
      // This is the critical P4.2 fix: an unrelated integration URL can no
      // longer force LoginRuntimeConfig.defaults.
      final LoginRuntimeConfig parsedLogin =
          LoginRuntimeConfig.fromAppConfig(config);
      _loginRuntimeConfig = parsedLogin;

      _appUpdatePolicy = _readAppUpdatePolicy(config);

      final String downloadDomain = _readOptionalHttpUrlSafely(
        config,
        'domainDownload',
      );
      final String ktxUrl = _readOptionalHttpUrlSafely(config, 'ktxApiUrl');
      final String vneidUrl = _readOptionalHttpUrlSafely(
        config,
        'vneidApiUrl',
      );
      final String cccdConfigUrl = _readOptionalHttpUrlSafely(
        config,
        'cccdConfigApiUrl',
      );
      final String zaloUrl = _readString(config, 'zaloGroupUrl');

      ServicesUrl().baseUrlFileDownload = downloadDomain;
      ServicesUrl().ktxApiUrl = ktxUrl;
      ServicesUrl().vneidApiUrl = vneidUrl;
      ServicesUrl().cccdConfigApiUrl = cccdConfigUrl;
      ServicesUrl().zaloGroupUrl = zaloUrl;

      _loadedSuccessfully = true;
      _lastLoadError = null;
      _publishZaloUrl(ServicesUrl().effectiveZaloGroupUrl);

      final AppUpdatePolicy? updatePolicy = _appUpdatePolicy;
      final String androidUpdate = updatePolicy == null
          ? '<none>'
          : 'enabled=${updatePolicy.android.enabled},'
              'min=${updatePolicy.android.minimumVersion},'
              'latest=${updatePolicy.android.latestVersion}';
      final String iosUpdate = updatePolicy == null
          ? '<none>'
          : 'enabled=${updatePolicy.ios.enabled},'
              'min=${updatePolicy.ios.minimumVersion},'
              'latest=${updatePolicy.ios.latestVersion}';

      logInfo(
        '[LOGIN_CONFIG] loaded=true '
        'idpLogin=${parsedLogin.idpLogin}, '
        'idpStartUrl=${parsedLogin.idpStartUrl.isEmpty ? "<empty>" : parsedLogin.idpStartUrl}, '
        'idpWebUrl=${parsedLogin.idpWebUrl.isEmpty ? "<empty>" : parsedLogin.idpWebUrl}, '
        'qrEnabled=${parsedLogin.qrEnabled}, '
        'passwordFallback=${parsedLogin.passwordFallbackEnabled}',
      );

      logInfo(
        'App config loaded from ${ServicesUrl.defaultBaseUrl}/api/config: '
        'ktxApiUrl=${ServicesUrl().effectiveKtxApiUrl}, '
        'vneidApiUrl=${ServicesUrl().effectiveVneidApiUrl}, '
        'cccdConfigApiUrl=${cccdConfigUrl.isEmpty ? "<not-configured>" : cccdConfigUrl}, '
        'domainDownload=${downloadDomain.isEmpty ? "<mobile-api>" : downloadDomain}, '
        'androidUpdate=$androidUpdate, iosUpdate=$iosUpdate, '
        'idpLogin=${parsedLogin.idpLogin}, '
        'qrEnabled=${parsedLogin.qrEnabled}, '
        'passwordFallback=${parsedLogin.passwordFallbackEnabled}',
      );
    } catch (error, stackTrace) {
      _lastLoadError = _friendlyLoadError(error);

      if (hadUsableConfig) {
        // A transient network error during a forced refresh must not destroy the
        // config that was already working. Keep login/integration values and
        // let the next explicit refresh try again.
        _loadedSuccessfully = true;
        _appUpdatePolicy = previousUpdatePolicy;
        _loginRuntimeConfig = previousLoginConfig;
        _publishZaloUrl(ServicesUrl().effectiveZaloGroupUrl);

        logError(
          '[LOGIN_CONFIG] refresh_failed=true keep_last_good=true '
          'error=$_lastLoadError\n$stackTrace',
        );
      } else {
        _loadedSuccessfully = false;
        _appUpdatePolicy = null;
        _loginRuntimeConfig = LoginRuntimeConfig.defaults;
        ServicesUrl().clearRemoteConfig();
        _publishZaloUrl(ServicesUrl.defaultZaloGroupUrl);

        logError(
          '[LOGIN_CONFIG] loaded=false error=$_lastLoadError\n$stackTrace',
        );
      }
    }
  }

  Future<Map<String, dynamic>> _fetchRemoteConfig() async {
    // Do not use the authenticated Dio factory here. The app config endpoint is a
    // public bootstrap endpoint and must not inherit Authorization headers,
    // token-expired redirect behavior, or other authenticated interceptors.
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: ServicesUrl.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: const <String, dynamic>{
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ),
    );

    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '/api/config',
        queryParameters: <String, dynamic>{
          '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final Map<String, dynamic> decoded = _decodeConfigObject(response.data);
      return _unwrapConfigEnvelope(decoded);
    } finally {
      dio.close(force: true);
    }
  }

  Map<String, dynamic> _decodeConfigObject(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    if (raw is String && raw.trim().isNotEmpty) {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw const FormatException('/api/config must return a JSON object');
  }

  Map<String, dynamic> _unwrapConfigEnvelope(Map<String, dynamic> input) {
    Map<String, dynamic> current = Map<String, dynamic>.from(input);

    // Current API returns the config directly. These two passes keep Flutter
    // compatible if the API is later standardized as {data:{...}} or
    // {result:{...}} without changing the mobile release.
    for (int i = 0; i < 2; i++) {
      final dynamic nested = current['data'] ?? current['result'];
      if (nested is! Map) break;

      final Map<String, dynamic> candidate =
          Map<String, dynamic>.from(nested);
      if (!_looksLikeAppConfig(candidate)) break;
      current = candidate;
    }

    if (!_looksLikeAppConfig(current)) {
      throw const FormatException(
        '/api/config JSON object does not contain ONEVNU config fields',
      );
    }

    return current;
  }

  bool _looksLikeAppConfig(Map<String, dynamic> map) {
    return map.containsKey('login') ||
        map.containsKey('ktxApiUrl') ||
        map.containsKey('vneidApiUrl') ||
        map.containsKey('appUpdate') ||
        map.containsKey('domainDownload') ||
        map.containsKey('zaloGroupUrl');
  }

  AppUpdatePolicy? _readAppUpdatePolicy(Map<String, dynamic> config) {
    final dynamic raw = config['appUpdate'];
    if (raw is! Map) return null;

    try {
      return AppUpdatePolicy.fromMap(Map<String, dynamic>.from(raw));
    } catch (error) {
      logError('Invalid appUpdate in /api/config: $error');
      return null;
    }
  }

  String _readString(Map<String, dynamic> config, String key) {
    return config[key]?.toString().trim() ?? '';
  }

  String _readOptionalHttpUrlSafely(
    Map<String, dynamic> config,
    String key,
  ) {
    final String value = _readString(config, key);
    if (value.isEmpty) return '';

    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      logError(
        '[APP_CONFIG] Ignore invalid $key from /api/config: $value',
      );
      return '';
    }

    return value;
  }

  String _friendlyLoadError(Object error) {
    if (error is DioException) {
      final int? status = error.response?.statusCode;
      if (status != null) {
        return 'Không tải được cấu hình đăng nhập (HTTP $status).';
      }
      return 'Không kết nối được máy chủ cấu hình đăng nhập.';
    }
    if (error is FormatException) {
      return 'Dữ liệu /api/config không đúng định dạng.';
    }
    return 'Không tải được cấu hình đăng nhập.';
  }

  void _publishZaloUrl(String value) {
    final String normalized = value.trim().isEmpty
        ? ServicesUrl.defaultZaloGroupUrl
        : value.trim();

    if (zaloGroupUrlNotifier.value != normalized) {
      zaloGroupUrlNotifier.value = normalized;
    }
  }
}
