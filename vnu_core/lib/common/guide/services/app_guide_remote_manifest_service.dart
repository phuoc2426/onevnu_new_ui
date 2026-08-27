import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../globals.dart';
import '../../../services/services_url.dart';
import '../remote/app_guide_remote_manifest.dart';

class AppGuideRemoteManifestService {
  const AppGuideRemoteManifestService();

  static const String _manifestCacheKey = 'app_guide_remote_manifest_v1';
  static const String _manifestCacheTimeKey =
      'app_guide_remote_manifest_cached_at_v1';
  static const String _manifestAppVersionKey =
      'app_guide_remote_manifest_app_version_v1';
  static const Duration _freshCacheAge = Duration(minutes: 15);

  Future<AppGuideRemoteManifest?> loadBestEffort() async {
    final cached = await loadCached();
    final cachedAt = await _cachedAt();
    final cacheIsFresh = cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) <= _freshCacheAge;

    // Stale-while-revalidate keeps the first-open guide fast on normal app
    // launches, while still refreshing the published server scenario.
    if (cacheIsFresh) {
      unawaited(refresh().then<void>((_) {}));
      return cached;
    }

    final remote = await refresh();
    return remote ?? cached;
  }

  Future<AppGuideRemoteManifest?> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_manifestCacheKey);
      if (raw == null || raw.trim().isEmpty) return null;

      // A manifest is already filtered server-side for the requesting app
      // version. Never reuse a fresh cache across an app upgrade/downgrade,
      // otherwise an old target set could be replayed against a new UI tree.
      final packageInfo = await PackageInfo.fromPlatform();
      final cachedAppVersion = prefs.getString(_manifestAppVersionKey);
      if (cachedAppVersion == null ||
          cachedAppVersion.trim() != packageInfo.version.trim()) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final manifest = AppGuideRemoteManifest.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return manifest.schemaVersion == 1 ? manifest : null;
    } catch (error) {
      debugPrint('[GUIDE_REMOTE_CACHE_ERROR] $error');
      return null;
    }
  }

  Future<AppGuideRemoteManifest?> refresh() async {
    try {
      await ServicesUrl().init();
      final packageInfo = await PackageInfo.fromPlatform();

      // Guide is optional infrastructure. Use an isolated short-timeout Dio
      // client instead of the global API interceptor so a guide-specific 401
      // or deployment issue can never log the user out or block the app.
      final token = Globals().token.trim();
      final dio = Dio(
        BaseOptions(
          baseUrl: ServicesUrl().baseUrl,
          connectTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1800),
          sendTimeout: const Duration(milliseconds: 1500),
          headers: token.isEmpty
              ? null
              : <String, dynamic>{'Authorization': 'Bearer $token'},
        ),
      );

      final response = await dio.get<dynamic>(
        'api/dynamic-guides/manifest',
        queryParameters: <String, dynamic>{
          'platform': 'AppMobile',
          'appVersion': packageInfo.version,
        },
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final dynamic rawData = response.data;
      final Map<String, dynamic> data;
      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else if (rawData is String) {
        final decoded = jsonDecode(rawData);
        if (decoded is! Map) return null;
        data = Map<String, dynamic>.from(decoded);
      } else {
        return null;
      }

      final manifest = AppGuideRemoteManifest.fromJson(data);
      if (manifest.schemaVersion != 1) {
        debugPrint(
          '[GUIDE_REMOTE_REJECT] unsupported schema=${manifest.schemaVersion}',
        );
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_manifestCacheKey, jsonEncode(data));
      await prefs.setString(
        _manifestCacheTimeKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      await prefs.setString(_manifestAppVersionKey, packageInfo.version);

      debugPrint(
        '[GUIDE_REMOTE_LOADED] revision=${manifest.manifestRevision} flows=${manifest.flows.length}',
      );
      return manifest;
    } on DioException catch (error) {
      debugPrint('[GUIDE_REMOTE_HTTP_ERROR] ${error.message}');
      return null;
    } catch (error) {
      debugPrint('[GUIDE_REMOTE_ERROR] $error');
      return null;
    }
  }

  Future<DateTime?> _cachedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_manifestCacheTimeKey);
      return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    } catch (_) {
      return null;
    }
  }
}
