import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/dio_options.dart';
import '../services/services_url.dart';
import 'log.dart';
import 'vnu_cache_manager.dart';

class AcademicPeriodRule {
  const AcademicPeriodRule({
    required this.periodNumber,
    this.startTime,
    this.endTime,
    this.autoStart = true,
    this.breakBeforeMinutes,
    this.manualOverride = false,
  });

  final int periodNumber;
  final String? startTime;
  final String? endTime;
  final bool autoStart;
  final int? breakBeforeMinutes;
  final bool manualOverride;

  factory AcademicPeriodRule.fromJson(Map<String, dynamic> json) {
    return AcademicPeriodRule(
      periodNumber: _asInt(json['periodNumber'] ?? json['period_number']) ?? 0,
      startTime: _asClock(json['startTime'] ?? json['start_time']),
      endTime: _asClock(json['endTime'] ?? json['end_time']),
      autoStart: _asBool(json['autoStart'] ?? json['auto_start'], fallback: true),
      breakBeforeMinutes:
          _asInt(json['breakBeforeMinutes'] ?? json['break_before_minutes']),
      manualOverride:
          _asBool(json['manualOverride'] ?? json['manual_override']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'periodNumber': periodNumber,
        'startTime': startTime,
        'endTime': endTime,
        'autoStart': autoStart,
        'breakBeforeMinutes': breakBeforeMinutes,
        'manualOverride': manualOverride,
      };
}

class AcademicClockRange {
  const AcademicClockRange({required this.startTime, required this.endTime});

  final String startTime;
  final String endTime;
}

class AcademicPeriodConfig {
  const AcademicPeriodConfig({
    required this.configured,
    required this.enabled,
    required this.lessonDurationMinutes,
    required this.defaultBreakMinutes,
    required this.firstPeriodStartTime,
    required this.maxPeriods,
    required this.periods,
    this.version,
    this.updatedAt,
  });

  final bool configured;
  final bool enabled;
  final int lessonDurationMinutes;
  final int defaultBreakMinutes;
  final String firstPeriodStartTime;
  final int maxPeriods;
  final List<AcademicPeriodRule> periods;
  final String? version;
  final DateTime? updatedAt;

  factory AcademicPeriodConfig.fromJson(Map<String, dynamic> raw) {
    final dynamic nested = raw['data'];
    final json = nested is Map
        ? Map<String, dynamic>.from(nested)
        : Map<String, dynamic>.from(raw);
    final rawPeriods = json['periods'] ?? json['periodRules'] ?? const [];

    return AcademicPeriodConfig(
      configured: _asBool(json['configured']),
      enabled: _asBool(json['enabled'], fallback: true),
      lessonDurationMinutes:
          (_asInt(json['lessonDurationMinutes'] ?? json['lesson_duration_minutes']) ?? 50)
              .clamp(1, 240).toInt(),
      defaultBreakMinutes:
          (_asInt(json['defaultBreakMinutes'] ?? json['default_break_minutes']) ?? 10)
              .clamp(0, 240).toInt(),
      firstPeriodStartTime:
          _asClock(json['firstPeriodStartTime'] ?? json['first_period_start_time']) ??
              '07:00',
      maxPeriods: (_asInt(json['maxPeriods'] ?? json['max_periods']) ?? 13)
          .clamp(1, 30).toInt(),
      periods: rawPeriods is List
          ? rawPeriods
              .whereType<Map>()
              .map((item) =>
                  AcademicPeriodRule.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.periodNumber > 0)
              .toList()
          : const <AcademicPeriodRule>[],
      version: json['version']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  /// Giữ nguyên 100% mapping giờ tiết đang hard-code ở project cũ.
  /// Nếu server chưa cấu hình / mất mạng / cache không có thì resolver vẫn
  /// trả đúng các mốc này, bao gồm khoảng nghỉ trưa Tiết 5 -> Tiết 6.
  factory AcademicPeriodConfig.projectDefault() {
    const starts = <int, String>{
      1: '07:00',
      2: '08:00',
      3: '09:00',
      4: '10:00',
      5: '11:00',
      6: '13:00',
      7: '14:00',
      8: '15:00',
      9: '16:00',
      10: '17:00',
      11: '18:00',
      12: '19:00',
      13: '20:00',
    };
    const ends = <int, String>{
      1: '07:50',
      2: '08:50',
      3: '09:50',
      4: '10:50',
      5: '11:50',
      6: '13:50',
      7: '14:50',
      8: '15:50',
      9: '16:50',
      10: '17:50',
      11: '18:50',
      12: '19:50',
      13: '20:50',
    };

    return AcademicPeriodConfig(
      configured: false,
      enabled: true,
      lessonDurationMinutes: 50,
      defaultBreakMinutes: 10,
      firstPeriodStartTime: '07:00',
      maxPeriods: 13,
      periods: List<AcademicPeriodRule>.generate(13, (index) {
        final period = index + 1;
        return AcademicPeriodRule(
          periodNumber: period,
          startTime: starts[period],
          endTime: ends[period],
          // Tiết 1 là mốc gốc; từ Tiết 2 trở đi đều tự nối từ tiết trước.
          // Tiết 6 chỉ khác ở thời gian nghỉ trước tiết (70 phút), không phải
          // một mốc manual, nhờ vậy thay đổi Tiết 5 vẫn lan truyền đúng.
          autoStart: period != 1,
          // Các tiết thường dùng defaultBreakMinutes; chỉ Tiết 6 có nghỉ riêng.
          breakBeforeMinutes: period == 6 ? 70 : null,
          manualOverride: false,
        );
      }),
      version: 'project-default-v1',
    );
  }

  AcademicPeriodConfig copyWith({
    bool? configured,
    bool? enabled,
    int? lessonDurationMinutes,
    int? defaultBreakMinutes,
    String? firstPeriodStartTime,
    int? maxPeriods,
    List<AcademicPeriodRule>? periods,
    String? version,
    DateTime? updatedAt,
  }) {
    return AcademicPeriodConfig(
      configured: configured ?? this.configured,
      enabled: enabled ?? this.enabled,
      lessonDurationMinutes:
          (lessonDurationMinutes ?? this.lessonDurationMinutes).clamp(1, 240).toInt(),
      defaultBreakMinutes:
          (defaultBreakMinutes ?? this.defaultBreakMinutes).clamp(0, 240).toInt(),
      firstPeriodStartTime:
          _asClock(firstPeriodStartTime) ?? this.firstPeriodStartTime,
      maxPeriods: (maxPeriods ?? this.maxPeriods).clamp(1, 30).toInt(),
      periods: periods ?? this.periods,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AcademicPeriodRule? ruleFor(int periodNumber) {
    for (final rule in periods) {
      if (rule.periodNumber == periodNumber) return rule;
    }
    return null;
  }

  AcademicPeriodConfig withPeriodRule(AcademicPeriodRule rule) {
    final updated = <AcademicPeriodRule>[
      for (final item in periods)
        if (item.periodNumber != rule.periodNumber) item,
      rule,
    ]..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

    return copyWith(
      configured: true,
      enabled: true,
      periods: updated,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'configured': configured,
        'enabled': enabled,
        'lessonDurationMinutes': lessonDurationMinutes,
        'defaultBreakMinutes': defaultBreakMinutes,
        'firstPeriodStartTime': firstPeriodStartTime,
        'maxPeriods': maxPeriods,
        'periods': periods.map((item) => item.toJson()).toList(),
        'version': version,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Map<int, AcademicClockRange> resolveAll() {
    if (!enabled) return const <int, AcademicClockRange>{};

    final rules = <int, AcademicPeriodRule>{
      for (final item in periods) item.periodNumber: item,
    };
    final result = <int, AcademicClockRange>{};

    for (var period = 1; period <= maxPeriods; period++) {
      final rule = rules[period];
      String? start;

      if (period == 1) {
        // Tiết 1 là mốc gốc. Nếu người dùng nhập riêng thì dùng startTime,
        // nếu không dùng firstPeriodStartTime.
        start = _asClock(rule?.startTime) ?? _asClock(firstPeriodStartTime);
      } else if (rule?.autoStart ?? true) {
        // Quan trọng: autoStart=true LUÔN nối từ giờ ra tiết trước + giờ nghỉ.
        // Không dùng startTime cũ đang lưu trong rule vì nếu dùng thì thay đổi
        // tiết trước sẽ không đẩy được các tiết phía sau.
        final previous = result[period - 1];
        if (previous != null) {
          start = addMinutes(
            previous.endTime,
            rule?.breakBeforeMinutes ?? defaultBreakMinutes,
          );
        }
      } else {
        start = _asClock(rule?.startTime);
      }

      if (start == null) continue;

      // endTime chỉ được coi là override khi manualOverride=true. Các rule
      // mặc định vẫn có endTime để fallback/hiển thị nhưng không cản việc đổi
      // lessonDurationMinutes và tự lan truyền giờ mới.
      final explicitEnd = rule?.manualOverride == true
          ? _asClock(rule?.endTime)
          : null;
      final end = explicitEnd ?? addMinutes(start, lessonDurationMinutes);
      if (end == null) continue;

      result[period] = AcademicClockRange(startTime: start, endTime: end);
    }

    return result;
  }

  AcademicClockRange? resolveLessonRange(
    String? startLesson,
    String? endLesson,
  ) {
    final startPeriod = _lessonNumber(startLesson);
    final endPeriod = _lessonNumber(endLesson) ?? startPeriod;
    if (startPeriod == null || endPeriod == null) return null;

    final resolved = resolveAll();
    final first = resolved[startPeriod];
    final last = resolved[endPeriod];
    if (first == null || last == null) return null;

    return AcademicClockRange(
      startTime: first.startTime,
      endTime: last.endTime,
    );
  }

  static String? addMinutes(String? hhmm, int minutes) {
    final value = _asClock(hhmm);
    if (value == null) return null;
    final parts = value.split(':');
    var total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    total %= 24 * 60;
    if (total < 0) total += 24 * 60;
    return '${(total ~/ 60).toString().padLeft(2, '0')}:'
        '${(total % 60).toString().padLeft(2, '0')}';
  }
}

class AcademicPeriodConfigRepository {
  AcademicPeriodConfigRepository({Dio? dio})
      : _dio = dio ?? DioOptions().createDio(ServicesUrl().baseUrl);

  static const _cacheKey = 'academic_period_config_lkg_v1';
  static const _personalCacheKey = 'vcore_academic_period_personal_v1.json';
  final Dio _dio;

  /// Resolve order:
  /// 1) cấu hình cá nhân trên app;
  /// 2) config server;
  /// 3) last-known-good cache khi server/network lỗi;
  /// 4) exact project default.
  Future<AcademicPeriodConfig> load({
    bool forceRefresh = false,
    bool ignorePersonal = false,
  }) async {
    final personal = ignorePersonal ? null : await loadPersonal();
    if (personal != null && personal.enabled) {
      logInfo(
        '[SCHEDULE_PERIOD_CONFIG] action=load source=personal '
        'duration=${personal.lessonDurationMinutes} '
        'break=${personal.defaultBreakMinutes}',
      );
      return personal;
    }

    try {
      final response = await _dio.get<dynamic>('api/academic-schedule-config');
      final raw = response.data;
      if (raw is Map) {
        final config = AcademicPeriodConfig.fromJson(
          Map<String, dynamic>.from(raw),
        );
        final prefs = await SharedPreferences.getInstance();
        if (config.configured && config.enabled) {
          await prefs.setString(_cacheKey, jsonEncode(config.toJson()));
          logInfo('[SCHEDULE_PERIOD_CONFIG] action=load source=server');
          return config;
        }

        await prefs.remove(_cacheKey);
        logInfo('[SCHEDULE_PERIOD_CONFIG] action=load source=project_default');
        return AcademicPeriodConfig.projectDefault();
      }
    } catch (error) {
      final cached = await _loadCache();
      if (cached != null) {
        logWarning(
          '[SCHEDULE_PERIOD_CONFIG] action=load source=lkg '
          'reason=${error.runtimeType}',
        );
        return cached;
      }
    }

    logInfo('[SCHEDULE_PERIOD_CONFIG] action=load source=project_default');
    return AcademicPeriodConfig.projectDefault();
  }

  Future<AcademicPeriodConfig?> loadPersonal() async {
    try {
      final raw = await VnuCacheFileManager().getCacheFile(_personalCacheKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AcademicPeriodConfig.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (error) {
      logError(
        '[SCHEDULE_PERIOD_CONFIG] action=load_personal status=failed '
        'error=${error.runtimeType}',
      );
      return null;
    }
  }

  Future<bool> hasPersonalOverride() async => (await loadPersonal()) != null;

  Future<bool> savePersonal(AcademicPeriodConfig config) async {
    final normalized = config.copyWith(
      configured: true,
      enabled: true,
      version: 'personal-v1',
      updatedAt: DateTime.now(),
    );
    final saved = await VnuCacheFileManager().saveCacheFile(
      _personalCacheKey,
      jsonEncode(normalized.toJson()),
    );
    if (saved) {
      logSuccess(
        '[SCHEDULE_PERIOD_CONFIG] action=save_personal status=success '
        'duration=${normalized.lessonDurationMinutes} '
        'break=${normalized.defaultBreakMinutes}',
      );
    } else {
      logError('[SCHEDULE_PERIOD_CONFIG] action=save_personal status=failed');
    }
    return saved;
  }

  Future<void> clearPersonal() async {
    await VnuCacheFileManager().deleteCacheFile(_personalCacheKey);
    logWarning('[SCHEDULE_PERIOD_CONFIG] action=clear_personal status=success');
  }

  Future<AcademicPeriodConfig?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey)?.trim() ?? '';
      if (raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AcademicPeriodConfig.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}

int? _lessonNumber(String? value) {
  final match = RegExp(r'\d+').firstMatch(value?.trim() ?? '');
  return int.tryParse(match?.group(0) ?? '');
}

String? _asClock(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
  if (match == null) return null;
  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

