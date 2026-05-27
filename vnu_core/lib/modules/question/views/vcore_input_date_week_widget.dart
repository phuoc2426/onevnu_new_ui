import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';

class VcoreInputDateWeekWidget extends StatefulWidget {
  final DateTime? startTime;
  final DateTime? endTime;
  final VoidCallback onSelectDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const VcoreInputDateWeekWidget({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onSelectDate,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<VcoreInputDateWeekWidget> createState() =>
      _VcoreInputDateWeekWidgetState();
}

class _VcoreInputDateWeekWidgetState extends State<VcoreInputDateWeekWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xff879ABF))),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                widget.onSelectDate();
              },
              child: Text(
                _getTime(),
                style: TextStyles.regular,
              ),
            ),
          ),
          svgAction(
            'assets/images/ic_arrow_previous.svg',
            color: widget.startTime != null ? null : Colors.grey,
            action: widget.startTime != null
                ? () {
                    widget.onPrevious();
                  }
                : null,
          ),
          svgAction(
            'assets/images/ic_arrow_next.svg',
            color: widget.endTime != null ? null : Colors.grey,
            action: widget.endTime != null
                ? () {
                    widget.onNext();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String _getTime() {
    if (widget.startTime == null && widget.endTime == null) {
      return 'Tất cả thời gian';
    }

    if (widget.startTime == null || widget.endTime == null) {
      return '-';
    }

    return '${DateTimeUtils.stringFromDateTime(widget.startTime, DateTimeConst.DATE_FORMAT)} - ${DateTimeUtils.stringFromDateTime(widget.endTime, DateTimeConst.DATE_FORMAT)}';
  }
}
