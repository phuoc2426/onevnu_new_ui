import 'package:vnu_core/models/hoc_ky_model.dart';

class HocKyDateRange {
  final DateTime start;
  final DateTime end;

  const HocKyDateRange({
    required this.start,
    required this.end,
  });

  bool contains(DateTime date) {
    final target = HocKyDateHelper.dateOnly(date);
    return !target.isBefore(start) && !target.isAfter(end);
  }
}

class HocKyDateHelper {
  HocKyDateHelper._();

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime? parseApiDate(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final isoDate = DateTime.tryParse(text);
    if (isoDate != null) return dateOnly(isoDate);

    final match = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(text);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final year = int.tryParse(match.group(3) ?? '');
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  static bool isExtraTerm(HocKyModel hocKy) {
    final loaiHocKy = hocKy.loaiHocKy?.trim().toUpperCase();
    if (loaiHocKy == 'HE_PHU') return true;

    final preTerm = hocKy.preTerm?.trim();
    return preTerm != null && preTerm.isNotEmpty;
  }

  static HocKyDateRange rangeFor(HocKyModel hocKy) {
    return rangeForDates(
      hocKy,
      startDate: hocKy.ngayBatDau,
      endDate: hocKy.ngayKetThuc,
    );
  }

  static HocKyDateRange rangeForDates(
    HocKyModel hocKy, {
    String? startDate,
    String? endDate,
  }) {
    final overrideRange = _apiRangeForDates(
      hocKy,
      startDate: startDate,
      endDate: endDate,
    );
    if (overrideRange != null) return overrideRange;
    final apiRange = _apiRangeFor(hocKy);
    if (apiRange != null) return apiRange;

    return _fallbackRangeFor(hocKy);
  }

  static HocKyModel? findContaining(
    List<HocKyModel> hocKyList,
    DateTime date,
  ) {
    final target = dateOnly(date);
    for (final hocKy in hocKyList) {
      if (rangeFor(hocKy).contains(target)) return hocKy;
    }
    return null;
  }

  static int? extractStartYear(String? nam) {
    final text = nam?.trim();
    if (text == null || text.isEmpty) return null;

    final match = RegExp(r'\d{4}').firstMatch(text);
    if (match == null) return null;

    return int.tryParse(match.group(0)!);
  }

  static HocKyDateRange? _apiRangeFor(HocKyModel hocKy) {
    return _apiRangeForDates(
      hocKy,
      startDate: hocKy.ngayBatDau,
      endDate: hocKy.ngayKetThuc,
    );
  }

  static HocKyDateRange? _apiRangeForDates(
    HocKyModel hocKy, {
    String? startDate,
    String? endDate,
  }) {
    final start = parseApiDate(startDate);
    final rawEnd = parseApiDate(endDate);
    if (start == null || rawEnd == null) return null;

    final end = rawEnd.isBefore(start) ? start : rawEnd;
    final durationDays = end.difference(start).inDays + 1;
    if (durationDays <= 0) return null;

    if (isExtraTerm(hocKy)) {
      if (durationDays > 75) {
        return HocKyDateRange(
          start: start,
          end: start.add(const Duration(days: 59)),
        );
      }
      return HocKyDateRange(start: start, end: end);
    }

    if (durationDays > 210) return null;
    return HocKyDateRange(start: start, end: end);
  }

  static HocKyDateRange _fallbackRangeFor(HocKyModel hocKy) {
    final yearText = hocKy.nam ?? '';
    final semesterName = hocKy.ten ?? '';
    int startYear = DateTime.now().year;

    final years = yearText.split('-');
    if (years.isNotEmpty) {
      startYear = int.tryParse(years[0]) ?? startYear;
    }

    int endYear = startYear + 1;
    if (years.length > 1) {
      endYear = int.tryParse(years[1]) ?? endYear;
    }

    final lowerName = semesterName.toLowerCase();
    if (semesterName.contains('1')) {
      return HocKyDateRange(
        start: DateTime(startYear, 8, 15),
        end: DateTime(endYear, 1, 15),
      );
    }

    if (semesterName.contains('2')) {
      return HocKyDateRange(
        start: DateTime(endYear, 2, 1),
        end: DateTime(endYear, 6, 30),
      );
    }

    if (semesterName.contains('3') ||
        lowerName.contains('he') ||
        lowerName.contains('he phu')) {
      return HocKyDateRange(
        start: DateTime(endYear, 7, 1),
        end: DateTime(endYear, 8, 15),
      );
    }

    return HocKyDateRange(
      start: DateTime(startYear, 9, 1),
      end: DateTime(endYear, 2, 28),
    );
  }
}
