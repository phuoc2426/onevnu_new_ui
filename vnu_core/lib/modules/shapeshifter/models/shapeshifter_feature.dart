import 'package:flutter/material.dart';

class ShapeshifterFeature {
  const ShapeshifterFeature({
    required this.code,
    required this.label,
    required this.groupCode,
    required this.webUrl,
    required this.allowedDomains,
    required this.audiences,
    required this.availableForStudent,
    required this.availableForAdmittedStudent,
    required this.showInHome,
    required this.showInMy,
    required this.mySortOrder,
    required this.colorStart,
    required this.colorEnd,
    required this.gradient,
    required this.gradientAngle,
    required this.defaultPinned,
    required this.showAppBar,
    required this.allowExternalNavigation,
    required this.sortOrder,
    this.description,
    this.iconUrl,
    this.authMode = 'BRIDGE_COOKIE',
    this.startAt,
    this.endAt,
  });

  final String code;
  final String label;
  final String? description;
  final String groupCode;
  final String? iconUrl;
  final String colorStart;
  final String colorEnd;
  final bool gradient;
  final int gradientAngle;
  final String webUrl;
  final String authMode;
  final List<String> allowedDomains;
  final List<String> audiences;
  final bool availableForStudent;
  final bool availableForAdmittedStudent;
  final bool showInHome;
  final bool showInMy;
  final int mySortOrder;
  final bool defaultPinned;
  final bool showAppBar;
  final bool allowExternalNavigation;
  final int sortOrder;
  final DateTime? startAt;
  final DateTime? endAt;

  String get stableKey => 'shape:$code';

  Color get primaryColor => parseHexColor(colorStart, const Color(0xFF007C3B));

  Color get secondaryColor => parseHexColor(colorEnd, primaryColor);

  factory ShapeshifterFeature.fromJson(Map<String, dynamic> json) {
    return ShapeshifterFeature(
      code: _string(json['code']),
      label: _string(json['label']),
      description: _nullableString(json['description']),
      groupCode: _string(json['groupCode'], fallback: 'DICH_VU'),
      iconUrl: _nullableString(json['iconUrl']),
      colorStart: _string(json['colorStart'], fallback: '#007C3B'),
      colorEnd: _string(json['colorEnd'], fallback: '#00A85A'),
      gradient: _bool(json['gradient'], fallback: true),
      gradientAngle: _int(json['gradientAngle'], fallback: 135),
      webUrl: _string(json['webUrl']),
      authMode: _string(json['authMode'], fallback: 'BRIDGE_COOKIE'),
      allowedDomains: _stringList(json['allowedDomains']),
      audiences: _stringList(json['audiences']),
      availableForStudent: _bool(
        json['availableForStudent'],
        fallback: _stringList(json['audiences']).contains('STUDENT'),
      ),
      availableForAdmittedStudent: _bool(
        json['availableForAdmittedStudent'],
        fallback: _stringList(json['audiences']).contains('APPLICANT'),
      ),
      showInHome: _bool(json['showInHome'], fallback: true),
      showInMy: _bool(json['showInMy']),
      mySortOrder: _int(json['mySortOrder'], fallback: 100),
      defaultPinned: _bool(json['defaultPinned']),
      showAppBar: _bool(json['showAppBar'], fallback: true),
      allowExternalNavigation: _bool(json['allowExternalNavigation']),
      sortOrder: _int(json['sortOrder'], fallback: 100),
      startAt: _date(json['startAt']),
      endAt: _date(json['endAt']),
    );
  }

  static Color parseHexColor(String? raw, Color fallback) {
    final value = (raw ?? '').trim().replaceFirst('#', '');
    if (value.length != 6 && value.length != 8) return fallback;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return fallback;
    return Color(value.length == 6 ? 0xFF000000 | parsed : parsed);
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return fallback;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    return const <String>[];
  }

  static DateTime? _date(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? null : DateTime.tryParse(raw);
  }
}
