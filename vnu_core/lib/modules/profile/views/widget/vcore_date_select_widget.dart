import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';

class VcoreDateSelectWidget extends StatefulWidget {
  final DateTime? date;
  final String hint;
  final Function(DateTime? selectedDate)? onChangeDate;
  const VcoreDateSelectWidget(
      {super.key, required this.date, required this.hint, this.onChangeDate});

  @override
  State<VcoreDateSelectWidget> createState() => _VcoreDateSelectWidgetState();
}

class _VcoreDateSelectWidgetState extends State<VcoreDateSelectWidget> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xff879ABF))),
      child: Row(
        children: [
          spaceWidth(12),
          Expanded(
              child: Text(
            widget.date == null
                ? widget.hint
                : DateTimeUtils.stringFromDateTime(
                    widget.date, DateTimeConst.DATE_FORMAT),
            style: TextStyles.regular.copyWith(
                color: widget.date == null
                    ? const Color(0xff879ABF)
                    : Colors.black),
          )),
          svgAction(
            'assets/images/ic_search_date.svg',
            action: () async {
              if (widget.onChangeDate == null) {
                return;
              }
              //choose date
              var results = await showCalendarDatePicker2Dialog(
                context: context,
                config: CalendarDatePicker2WithActionButtonsConfig(
                    calendarType: CalendarDatePicker2Type.single),
                dialogSize: const Size(325, 400),
                // value: _dates,
                borderRadius: BorderRadius.circular(15),
              );
              if (results?.firstOrNull != null && widget.onChangeDate != null) {
                widget.onChangeDate!(results?.first);
              }
            },
          ),
        ],
      ),
    );
  }
}
