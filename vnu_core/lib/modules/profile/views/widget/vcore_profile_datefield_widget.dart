import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';

import 'vcore_date_select_widget.dart';

class VcoreProfileDatefieldWidget extends StatefulWidget {
  final String title;
  final String hintText;
  final DateTime? value;
  final bool isRequired;
  final bool isDisable;

  final Function(DateTime? selectedDate)? onChangeDate;

  const VcoreProfileDatefieldWidget({
    super.key,
    required this.title,
    required this.hintText,
    this.value,
    this.isRequired = false,
    this.isDisable = false,
    this.onChangeDate,
  });

  @override
  State<VcoreProfileDatefieldWidget> createState() =>
      _VcoreProfileDatefieldWidgetState();
}

class _VcoreProfileDatefieldWidgetState
    extends State<VcoreProfileDatefieldWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: TextStyles.regular
                  .copyWith(fontSize: AppFontSizes.mediumSmall, color: Colors.black),
            ),
            Text(
              widget.isRequired ? ' *' : '',
              style:
                  TextStyles.regular.copyWith(fontSize: AppFontSizes.mediumSmall, color: Colors.red),
            )
          ],
        ),
        spaceHeight(8),
        SizedBox(
          height: 40,
          child: VcoreDateSelectWidget(
            date: widget.value,
            hint: widget.hintText,
            onChangeDate: widget.isDisable ? null : widget.onChangeDate,
          ),
        ),
      ],
    );
  }
}
