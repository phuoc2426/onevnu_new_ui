import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/widgets/field/vnu_readonly_field.dart';

/// Legacy profile adapter backed by the shared P2V2 field surface.
@Deprecated('Use VnuReadOnlyField/VNU date field from vnu_core/widgets/field')
class VcoreProfileDatefieldWidget extends StatelessWidget {
  const VcoreProfileDatefieldWidget({
    super.key,
    required this.title,
    required this.hintText,
    this.value,
    this.isRequired = false,
    this.isDisable = false,
    this.onChangeDate,
  });

  final String title;
  final String hintText;
  final DateTime? value;
  final bool isRequired;
  final bool isDisable;
  final Function(DateTime? selectedDate)? onChangeDate;

  Future<void> _pickDate(BuildContext context) async {
    if (isDisable || onChangeDate == null) return;
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
      value: value == null ? const <DateTime?>[] : <DateTime?>[value],
    );
    if (results?.firstOrNull != null) {
      onChangeDate?.call(results?.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? ''
        : DateTimeUtils.stringFromDateTime(value, DateTimeConst.DATE_FORMAT);

    return VnuReadOnlyField(
      label: title,
      displayText: display,
      placeholder: hintText,
      requiredField: isRequired,
      enabled: !isDisable,
      onTap: isDisable ? null : () => _pickDate(context),
      trailing: const Icon(
        Icons.calendar_month_outlined,
        size: 20,
        color: Color(0xFF16A34A),
      ),
    );
  }
}
