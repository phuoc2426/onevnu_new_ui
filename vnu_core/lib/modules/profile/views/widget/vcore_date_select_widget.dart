import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/widgets/field/vnu_readonly_field.dart';

@Deprecated('Use VnuReadOnlyField/VNU date field from vnu_core/widgets/field')
class VcoreDateSelectWidget extends StatelessWidget {
  const VcoreDateSelectWidget({
    super.key,
    required this.date,
    required this.hint,
    this.onChangeDate,
  });

  final DateTime? date;
  final String hint;
  final Function(DateTime? selectedDate)? onChangeDate;

  Future<void> _pick(BuildContext context) async {
    if (onChangeDate == null) return;
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
      value: date == null ? const <DateTime?>[] : <DateTime?>[date],
    );
    if (results?.firstOrNull != null) {
      onChangeDate?.call(results?.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VnuReadOnlyField(
      displayText: date == null
          ? ''
          : DateTimeUtils.stringFromDateTime(date, DateTimeConst.DATE_FORMAT),
      placeholder: hint,
      onTap: onChangeDate == null ? null : () => _pick(context),
      trailing: const Icon(
        Icons.calendar_month_outlined,
        size: 20,
        color: Color(0xFF16A34A),
      ),
      compact: true,
    );
  }
}
