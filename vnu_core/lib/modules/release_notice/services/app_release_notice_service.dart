import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/release_notice/models/app_release_notice.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

class AppReleaseNoticeService {
  AppReleaseNoticeService._internal()
      : _dio = DioOptions().createDio(ServicesUrl().baseUrl);

  static final AppReleaseNoticeService _instance =
      AppReleaseNoticeService._internal();

  factory AppReleaseNoticeService() => _instance;

  static const String _installIdKey = 'onevnu_install_id_v1';
  static const String _cachePrefix = 'onevnu_release_notice_cache_v1_';
  static const String _ackPrefix = 'onevnu_release_notice_ack_v1_';

  final Dio _dio;

  Future<List<AppReleaseNotice>> loadActive({
    String placement = 'PRE_LOGIN',
    bool forceRefresh = true,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String installId = await _installId(prefs);
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String platform = _platform;
    final String version = info.buildNumber.trim().isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
    final String cacheKey = '$_cachePrefix${placement.toUpperCase()}';

    if (forceRefresh) {
      try {
        final Response<dynamic> response = await _dio.get<dynamic>(
          '/api/app-release-notices/active',
          queryParameters: <String, dynamic>{
            'platform': platform,
            'version': version,
            'installId': installId,
            'placement': placement,
          },
          options: Options(
            headers: <String, dynamic>{
              'X-OneVNU-Install-Id': installId,
              'X-OneVNU-App-Version': version,
              'X-OneVNU-Platform': platform.toLowerCase(),
            },
          ),
        );

        final List<AppReleaseNotice> notices = _parseList(response.data);
        await prefs.setString(
          cacheKey,
          jsonEncode(notices.map((AppReleaseNotice e) => e.toJson()).toList()),
        );
        final List<AppReleaseNotice> filtered =
            await _filterLocalAcknowledged(prefs, notices);
        logInfo(
          '[RELEASE_NOTICE] fetch success placement=$placement '
          'status=${response.statusCode} count=${filtered.length}',
        );
        return filtered;
      } catch (error, stackTrace) {
        logError(
          '[RELEASE_NOTICE] fetch failed placement=$placement '
          'error=$error\n$stackTrace',
        );
      }
    }

    final List<AppReleaseNotice> cached = _loadCached(prefs, cacheKey);
    final List<AppReleaseNotice> filtered =
        await _filterLocalAcknowledged(prefs, cached);
    logInfo(
      '[RELEASE_NOTICE] using cache placement=$placement count=${filtered.length}',
    );
    return filtered;
  }

  Future<bool> isAcknowledged(AppReleaseNotice notice) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ackKey(notice)) == true;
  }

  Future<void> acknowledge(AppReleaseNotice notice) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String installId = await _installId(prefs);
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String version = info.buildNumber.trim().isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';

    // User acknowledgement must not be lost merely because the acknowledgement
    // API is temporarily unavailable. The server write is best-effort and the
    // local revision-aware key prevents repeated annoyance on this device.
    await prefs.setBool(_ackKey(notice), true);

    if (notice.id <= 0) {
      logInfo(
        '[RELEASE_NOTICE] local fallback acknowledged '
        'code=${notice.code} revision=${notice.revision}',
      );
      return;
    }

    try {
      await _dio.post<void>(
        '/api/app-release-notices/${notice.id}/ack',
        data: <String, dynamic>{
          'installId': installId,
          'noticeRevision': notice.revision,
          'appVersion': version,
          'platform': _platform,
        },
        options: Options(
          headers: <String, dynamic>{
            'X-OneVNU-Install-Id': installId,
            'X-OneVNU-App-Version': version,
            'X-OneVNU-Platform': _platform.toLowerCase(),
          },
        ),
      );
      logInfo(
        '[RELEASE_NOTICE] ack success id=${notice.id} '
        'code=${notice.code} revision=${notice.revision}',
      );
    } catch (error, stackTrace) {
      logError(
        '[RELEASE_NOTICE] ack server failed but local ack kept '
        'id=${notice.id} code=${notice.code} revision=${notice.revision} '
        'error=$error\n$stackTrace',
      );
    }
  }

  Future<AppReleaseNotice?> findByCode(
    String code, {
    String placement = 'PRE_LOGIN',
  }) async {
    final List<AppReleaseNotice> notices = await loadActive(
      placement: placement,
      forceRefresh: true,
    );
    final String expected = code.trim().toUpperCase();
    for (final AppReleaseNotice notice in notices) {
      if (notice.code.trim().toUpperCase() == expected) {
        return notice;
      }
    }
    return null;
  }

  List<AppReleaseNotice> _parseList(dynamic raw) {
    if (raw is! List) return <AppReleaseNotice>[];
    final List<AppReleaseNotice> result = <AppReleaseNotice>[];
    for (final dynamic item in raw) {
      if (item is Map) {
        result.add(
          AppReleaseNotice.fromJson(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }
    result.sort(
      (AppReleaseNotice a, AppReleaseNotice b) =>
          b.priority.compareTo(a.priority),
    );
    return result;
  }

  List<AppReleaseNotice> _loadCached(
    SharedPreferences prefs,
    String cacheKey,
  ) {
    try {
      final String raw = prefs.getString(cacheKey)?.trim() ?? '';
      if (raw.isEmpty) return <AppReleaseNotice>[];
      return _parseList(jsonDecode(raw));
    } catch (error, stackTrace) {
      logError('[RELEASE_NOTICE] cache parse failed: $error\n$stackTrace');
      return <AppReleaseNotice>[];
    }
  }

  Future<List<AppReleaseNotice>> _filterLocalAcknowledged(
    SharedPreferences prefs,
    List<AppReleaseNotice> notices,
  ) async {
    return notices
        .where((AppReleaseNotice notice) => prefs.getBool(_ackKey(notice)) != true)
        .toList(growable: false);
  }

  String _ackKey(AppReleaseNotice notice) =>
      '$_ackPrefix${notice.code}_${notice.id}_${notice.revision}';

  Future<String> _installId(SharedPreferences prefs) async {
    final String current = prefs.getString(_installIdKey)?.trim() ?? '';
    if (current.isNotEmpty) return current;
    final String generated = const Uuid().v4();
    await prefs.setString(_installIdKey, generated);
    return generated;
  }

  String get _platform {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'ALL';
  }
}
