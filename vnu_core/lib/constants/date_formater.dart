// ignore_for_file: constant_identifier_names, non_constant_identifier_names, depend_on_referenced_packages
import 'package:intl/intl.dart';

class Formatter {
  static final Date = _DateFormat();
}

class _DateFormat {
  _DateFormat();

  static const locale = 'vi';

  final short = DateFormat('yyyy/MM/dd', locale);
  final monthYear = DateFormat('yyyy/MM', locale);
  final serverFullDateTime = DateFormat('yyyy-MM-dd HH:mm:ss', locale);
  final serverDate = DateFormat('yyyy-MM-dd', locale);
  final japaneseDate = DateFormat('yyyy年MM月dd日', locale);
  final japaneseFullDate = DateFormat(
    'yyyy年MM月dd日EEE',
    locale,
  );
  final japaneseDayOfWeek = DateFormat('EEE', locale);
  final timeOfDate = DateFormat('HH:mm', locale);
  final timeFull = DateFormat('HH:mm:ss', locale);
}
