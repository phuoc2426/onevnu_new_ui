import 'package:intl/intl.dart';

/// Date-only codec for dormitory profile/registration fields.
///
/// DOB and identity issue dates are calendar dates, not instants. Their value
/// must never change because of UTC/local timezone conversion.
class DormitoryDateCodec {
  DormitoryDateCodec._();

  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayDashFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _slashIsoFormat = DateFormat('yyyy/MM/dd');
  static final RegExp _isoDatePrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

  static String? normalizeNullable(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      // Use the DateTime calendar components exactly as provided. Do not call
      // toUtc()/toLocal() because DOB is not a point on the global timeline.
      return _canonical(value.year, value.month, value.day);
    }

    final String raw = value.toString().trim();
    if (raw.isEmpty) return null;

    // The KTX API may return a date with time/offset. For a date-only field we
    // intentionally preserve the lexical YYYY-MM-DD part before any timezone
    // parsing. Example: 2005-09-11T17:00:00-07:00 stays 2005-09-11.
    final Match? iso = _isoDatePrefix.firstMatch(raw);
    if (iso != null) {
      final int? year = int.tryParse(iso.group(1)!);
      final int? month = int.tryParse(iso.group(2)!);
      final int? day = int.tryParse(iso.group(3)!);
      if (year != null && month != null && day != null) {
        return _canonical(year, month, day);
      }
    }

    // Accept common date-only text forms if they reach the codec from a text
    // field, while still emitting only YYYY-MM-DD to the KTX API. Never return
    // an unparsed datetime string: outbound DOB must contain date only.
    for (final DateFormat format in <DateFormat>[
      _displayFormat,
      _displayDashFormat,
      _slashIsoFormat,
    ]) {
      try {
        final DateTime parsed = format.parseStrict(raw);
        return _canonical(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        // Try the next date-only representation.
      }
    }

    throw FormatException('Định dạng ngày không hợp lệ: $raw');
  }

  static String normalize(dynamic value) => normalizeNullable(value) ?? '';

  static String _canonical(int year, int month, int day) {
    final DateTime validated = DateTime.utc(year, month, day);
    if (validated.year != year ||
        validated.month != month ||
        validated.day != day) {
      throw FormatException('Ngày không hợp lệ: $year-$month-$day');
    }
    return _apiFormat.format(validated);
  }
}
