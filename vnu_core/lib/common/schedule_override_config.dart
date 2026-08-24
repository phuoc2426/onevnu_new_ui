import 'dart:convert';

import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/models/hoc_ky_model.dart';
import 'package:vnu_core/models/thoi_khoa_bieu_model.dart';

const String kScheduleOverrideConfigCacheKey =
    'vcore_schedule_override_config.json';

class ScheduleOverrideConfig {
  final Map<String, ScheduleTermOverride> terms;
  final Map<String, ScheduleCourseOverride> courses;

  const ScheduleOverrideConfig({
    required this.terms,
    required this.courses,
  });

  factory ScheduleOverrideConfig.empty() {
    return const ScheduleOverrideConfig(
      terms: {},
      courses: {},
    );
  }

  factory ScheduleOverrideConfig.fromJson(Map<String, dynamic> json) {
    final rawTerms = json['terms'];
    final rawCourses = json['courses'];

    return ScheduleOverrideConfig(
      terms: rawTerms is Map
          ? rawTerms.map(
              (key, value) => MapEntry(
                key.toString(),
                ScheduleTermOverride.fromJson(_asMap(value)),
              ),
            )
          : {},
      courses: rawCourses is Map
          ? rawCourses.map(
              (key, value) => MapEntry(
                key.toString(),
                ScheduleCourseOverride.fromJson(_asMap(value)),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'terms': terms.map((key, value) => MapEntry(key, value.toJson())),
      'courses': courses.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Returns the term override for [hocKy].
  ///
  /// [scope] is used by the timetable screen to separate the same TERM_ID
  /// between TruongChinh / BangKep / TruongGui. The cache file itself is
  /// already separated by username by VnuCacheFileManager.
  ScheduleTermOverride? termFor(
    HocKyModel hocKy, {
    String? scope,
  }) {
    for (final key in _termLookupKeys(hocKy, scope: scope)) {
      final override = terms[key];
      if (override != null) return override;
    }
    return null;
  }

  bool hasScopedTermOverride(
    HocKyModel hocKy, {
    required String scope,
  }) {
    return _scopedTermKeys(hocKy, scope: scope)
        .any((key) => terms.containsKey(key));
  }

  ScheduleOverrideConfig withTermOverride(
    HocKyModel hocKy,
    ScheduleTermOverride? override, {
    String? scope,
  }) {
    final updatedTerms = Map<String, ScheduleTermOverride>.from(terms);
    final keys = scope == null || scope.trim().isEmpty
        ? _termBaseKeys(hocKy)
        : _scopedTermKeys(hocKy, scope: scope);

    for (final key in keys) {
      updatedTerms.remove(key);
    }

    if (override != null && keys.isNotEmpty) {
      updatedTerms[keys.first] = override;
    }

    return ScheduleOverrideConfig(
      terms: updatedTerms,
      courses: courses,
    );
  }

  ScheduleCourseOverride? courseFor(
    HocKyModel hocKy,
    ThoiKhoaBieuModel course,
  ) {
    for (final key in _courseKeys(hocKy, course)) {
      final override = courses[key];
      if (override != null) return override;
    }
    return null;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static List<String> _termBaseKeys(HocKyModel hocKy) {
    return [
      hocKy.id,
      hocKy.maHocKy,
      [hocKy.ten, hocKy.nam].where(_hasText).join('|'),
    ].whereType<String>().where(_hasText).toList();
  }

  static List<String> _scopedTermKeys(
    HocKyModel hocKy, {
    required String scope,
  }) {
    final cleanScope = _clean(scope);
    if (cleanScope == null) return _termBaseKeys(hocKy);
    return _termBaseKeys(hocKy)
        .map((key) => '$cleanScope|$key')
        .toList();
  }

  static List<String> _termLookupKeys(
    HocKyModel hocKy, {
    String? scope,
  }) {
    final baseKeys = _termBaseKeys(hocKy);
    final cleanScope = _clean(scope);
    if (cleanScope == null) return baseKeys;

    return [
      ...baseKeys.map((key) => '$cleanScope|$key'),
      ...baseKeys,
    ];
  }

  static List<String> _courseKeys(HocKyModel hocKy, ThoiKhoaBieuModel course) {
    final termKeys = _termBaseKeys(hocKy);
    final courseCode = _clean(course.maHocPhan);
    final group = _clean(course.nhom);
    final subject = _clean(course.tenHocPhan);
    final keys = <String>[];

    for (final termKey in termKeys) {
      if (_hasText(courseCode) && _hasText(group)) {
        keys.add('$termKey|$courseCode|$group');
      }
      if (_hasText(courseCode)) {
        keys.add('$termKey|$courseCode');
      }
      if (_hasText(subject) && _hasText(group)) {
        keys.add('$termKey|$subject|$group');
      }
      if (_hasText(subject)) {
        keys.add('$termKey|$subject');
      }
    }

    return keys;
  }

  static String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static bool _hasText(Object? value) {
    return value is String && value.trim().isNotEmpty;
  }
}

class ScheduleTermOverride {
  final String? startDate;
  final String? endDate;

  const ScheduleTermOverride({
    this.startDate,
    this.endDate,
  });

  factory ScheduleTermOverride.fromJson(Map<String, dynamic> json) {
    return ScheduleTermOverride(
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
  }
}

class ScheduleCourseOverride {
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;

  const ScheduleCourseOverride({
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
  });

  factory ScheduleCourseOverride.fromJson(Map<String, dynamic> json) {
    return ScheduleCourseOverride(
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
    };
  }
}

class ScheduleOverrideConfigCache {
  ScheduleOverrideConfigCache._internal();

  static final ScheduleOverrideConfigCache _singleton =
      ScheduleOverrideConfigCache._internal();

  factory ScheduleOverrideConfigCache() => _singleton;

  Future<ScheduleOverrideConfig> load() async {
    final raw =
        await VnuCacheFileManager().getCacheFile(kScheduleOverrideConfigCacheKey);
    if (raw == null || raw.trim().isEmpty) {
      final empty = ScheduleOverrideConfig.empty();
      await save(empty);
      return empty;
    }

    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return ScheduleOverrideConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return ScheduleOverrideConfig.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {}

    return ScheduleOverrideConfig.empty();
  }

  Future<void> save(ScheduleOverrideConfig config) async {
    await VnuCacheFileManager().saveCacheFile(
      kScheduleOverrideConfigCacheKey,
      json.encode(config.toJson()),
    );
  }
}
