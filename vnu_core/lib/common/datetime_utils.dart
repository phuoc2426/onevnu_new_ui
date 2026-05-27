import 'package:intl/intl.dart';
import '../constants/datetime_const.dart';

// ignore: avoid_classes_with_only_static_members
class DateTimeUtils {
  static var nullDate = DateTimeConst.nullDate;

  static String getFormattedDateTime({required DateTime dateTime}) {
    final day = '${dateTime.day}';
    final month = '${dateTime.month}';
    final year = '${dateTime.year}';

    // String hour = '${dateTime.hour}';
    // String minute = '${dateTime.minute}';
    // String second = '${dateTime.second}';
    //return '$day/$month/$year $hour/$minute/$second';
    return '$day/$month/$year';
  }

  static String formatDateTime(DateTime dateTime) {
    if (dateTime == null) {
      return '';
    }
    String time;
    if (dateTime is String) {
      if (dateTime.toString().trim() == '') {
        time = '';
      } else {
        time = dateTime.toString();
        final date = DateFormat(DateTimeConst.DATE_TIME_FORMAT).parse(time);
        time = DateFormat(DateTimeConst.U_MINUTE_FORMAT).format(date);
      }
    } else {
      time = DateFormat(DateTimeConst.U_MINUTE_FORMAT).format(dateTime);
    }
    return time;
  }

  static String formatDate(DateTime dateTime) {
    if (dateTime == null) {
      return '';
    }
    String time;
    if (dateTime is String) {
      if (dateTime.toString().trim() == '') {
        time = '';
      } else {
        time = dateTime.toString();
        final date = DateFormat(DateTimeConst.DATE_TIME_FORMAT).parse(time);
        time = DateFormat(DateTimeConst.DATE_FORMAT).format(date);
      }
    } else {
      time = DateFormat(DateTimeConst.DATE_FORMAT).format(dateTime);
    }
    return time;
  }

  static String formatDateV2(DateTime dateTime) {
    if (dateTime == null) {
      return '';
    }
    String time;
    if (dateTime is String) {
      if (dateTime.toString().trim() == '') {
        time = '';
      } else {
        time = dateTime.toString();
        final date = DateFormat(DateTimeConst.DATE_TIME_FORMAT).parse(time);
        time = DateFormat(DateTimeConst.DATE_3_FORMAT).format(date);
      }
    } else {
      time = DateFormat(DateTimeConst.DATE_3_FORMAT).format(dateTime);
    }
    return time;
  }

  static String formatMoth(DateTime dateTime) {
    if (dateTime == null) {
      return '';
    }
    String time;
    time = '${dateTime.month}/${dateTime.year}';
    return time;
  }

  static String stringFromDate(String? dateString, String format) {
    if (dateString == null) return '';
    String date = DateFormat(
      format,
      'vi_VN',
    ).format(DateTime.parse(dateString).toLocal());
    return date;
  }

  static String stringFromDateTime(DateTime? dateTime, String format) {
    if (dateTime == null) return '';
    String date = DateFormat(
      format,
      'vi_VN',
    ).format(dateTime.toLocal());
    return date;
  }
}
