import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

/// Loads /api/config from the fixed ONEVNU mobile API.
///
/// Concurrent callers share one request. A successful result is reused only
/// for the current app process; every new app launch fetches fresh config.
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

  bool get isLoadedSuccessfully => _loadedSuccessfully;

  String get effectiveZaloGroupUrl {
    final String current = zaloGroupUrlNotifier.value.trim();
    if (current.isNotEmpty) {
      return current;
    }
    return ServicesUrl().effectiveZaloGroupUrl;
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

    // Do not allow an obsolete persisted endpoint to survive a failed refresh.
    ServicesUrl().clearRemoteConfig();
    _publishZaloUrl(ServicesUrl.defaultZaloGroupUrl);

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
    try {
      final Map<String, dynamic> config = await _fetchRemoteConfig();

      final String downloadDomain = _readOptionalHttpUrl(
        config,
        'domainDownload',
      );
      final String ktxUrl = _readRequiredHttpUrl(config, 'ktxApiUrl');
      final String vneidUrl = _readRequiredHttpUrl(config, 'vneidApiUrl');
      final String cccdConfigUrl = _readOptionalHttpUrl(
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
      _publishZaloUrl(ServicesUrl().effectiveZaloGroupUrl);

      logInfo(
        'App config loaded from ${ServicesUrl.defaultBaseUrl}/api/config: '
        'ktxApiUrl=${ServicesUrl().effectiveKtxApiUrl}, '
        'vneidApiUrl=${ServicesUrl().effectiveVneidApiUrl}, '
        'cccdConfigApiUrl=${cccdConfigUrl.isEmpty ? "<not-configured>" : cccdConfigUrl}, '
        'domainDownload=${downloadDomain.isEmpty ? "<mobile-api>" : downloadDomain}',
      );
    } catch (error, stackTrace) {
      _loadedSuccessfully = false;
      ServicesUrl().clearRemoteConfig();
      _publishZaloUrl(ServicesUrl.defaultZaloGroupUrl);
      logError('Load app config error: $error\n$stackTrace');
    }
  }

  Future<Map<String, dynamic>> _fetchRemoteConfig() async {
    final Dio dio = DioOptions().createDio(ServicesUrl().baseUrl);

    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '/api/config',
        queryParameters: <String, dynamic>{
          '_ts': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(
          headers: const <String, dynamic>{
            'Accept': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );

      final dynamic raw = response.data;
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
    } finally {
      dio.close(force: true);
    }
  }

  String _readString(Map<String, dynamic> config, String key) {
    return config[key]?.toString().trim() ?? '';
  }

  String _readRequiredHttpUrl(Map<String, dynamic> config, String key) {
    final String value = _readString(config, key);
    final Uri? uri = Uri.tryParse(value);

    if (value.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw StateError('Invalid or missing $key in /api/config');
    }

    return value;
  }

  String _readOptionalHttpUrl(Map<String, dynamic> config, String key) {
    final String value = _readString(config, key);
    if (value.isEmpty) return '';

    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw StateError('Invalid $key in /api/config');
    }

    return value;
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
