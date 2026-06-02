import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';

import '../../../exam_schedule/views/vcore_dropdown_select_widget.dart';

class VcoreProfileDropdownfieldWidget extends StatefulWidget {
  final String title;
  final String hintText;
  final String? value;
  final bool isRequired;
  final List<String> items;
  final void Function(String value)? onSelected;

  const VcoreProfileDropdownfieldWidget({
    super.key,
    required this.title,
    required this.hintText,
    this.value,
    this.isRequired = false,
    required this.items,
    this.onSelected,
  });

  @override
  State<VcoreProfileDropdownfieldWidget> createState() =>
      _VcoreProfileDropdownfieldWidgetState();
}

class _VcoreProfileDropdownfieldWidgetState
    extends State<VcoreProfileDropdownfieldWidget> {
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
          child: VcoreDropdownSelectWidget(
            items: widget.items,
            hint: widget.hintText,
            value: widget.value,
            onSelected: widget.onSelected,
          ),
        ),
      ],
    );
  }
}
