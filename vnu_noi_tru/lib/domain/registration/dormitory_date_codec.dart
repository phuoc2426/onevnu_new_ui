import 'package:intl/intl.dart';

/// Date-only codec for dormitory profile/registration fields.
///
/// DOB and identity issue dates are calendar dates, not instants. Never move
/// them through UTC conversion because that can shift the visible day.
class DormitoryDateCodec {
  DormitoryDateCodec._();

  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');

  static String? normalizeNullable(dynamic value) {
    if (value == null) return null;
    final String raw = value is DateTime
        ? _apiFormat.format(value)
        : value.toString().trim();
    if (raw.isEmpty) return null;

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return raw;
    }

    try {
      return _apiFormat.format(DateTime.parse(raw));
    } catch (_) {
      return raw.split('T').first;
    }
  }

  static String normalize(dynamic value) => normalizeNullable(value) ?? '';
}
