import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/extensions/iterables.dart';

import '../../../common/utils.dart';

class VcoreDropdownSelectWidget<T> extends StatefulWidget {
  final List<String> items;
  final String hint;
  final String? value;
  final void Function(String value)? onSelected;

  const VcoreDropdownSelectWidget({
    super.key,
    required this.items,
    required this.hint,
    required this.value,
    this.onSelected,
  });

  @override
  State<VcoreDropdownSelectWidget> createState() =>
      _VcoreDropdownSelectWidgetState();
}

class _VcoreDropdownSelectWidgetState extends State<VcoreDropdownSelectWidget> {
  late final ValueNotifier<String?> selectedValueNotifier;

  @override
  void initState() {
    super.initState();
    selectedValueNotifier = ValueNotifier<String?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant VcoreDropdownSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      selectedValueNotifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    selectedValueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dropdownBorder),
        ),
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            widget.hint,
            style:
                TextStyles.regular.copyWith(color: Theme.of(context).hintColor),
          ),
          underline: Divider(
            color: Theme.of(context).hintColor,
          ),
          dropdownStyleData: const DropdownStyleData(
            maxHeight: 300,
            padding: EdgeInsets.symmetric(vertical: 6),
          ),
          items: widget.items
              .map(
                (String item) => DropdownItem<String>(
                  value: item,
                  height: 40,
                  child: Text(
                    item,
                    style: TextStyles.regular,
                    maxLines: 3,
                  ),
                ),
              )
              .toList(),
          valueListenable: selectedValueNotifier,
          onChanged: (String? value) {
            if (widget.onSelected != null) {
              widget.onSelected!(value ?? '');
            }
            selectedValueNotifier.value = value;
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            width: 140,
          ),
          menuItemStyleData: const MenuItemStyleData(),
          iconStyleData:
              IconStyleData(icon: svgAsset('assets/images/ic_dropdown.svg')),
        ),
      ),
    );
  }
}

class VcoreDropdownModel {
  const VcoreDropdownModel({
    required this.text,
    required this.guid,
  });

  final String text;
  final String guid;
}

class VcoreDropdown2SelectWidget extends StatefulWidget {
  final List<VcoreDropdownModel> items;
  final String hint;
  final String? selectedGuid;
  final void Function(VcoreDropdownModel value)? onSelected;

  const VcoreDropdown2SelectWidget({
    super.key,
    required this.items,
    required this.hint,
    required this.selectedGuid,
    this.onSelected,
  });

  @override
  State<VcoreDropdown2SelectWidget> createState() =>
      _VcoreDropdown2SelectWidgetState();
}

class _VcoreDropdown2SelectWidgetState
    extends State<VcoreDropdown2SelectWidget> {
  late final ValueNotifier<VcoreDropdownModel?> selectedValueNotifier;

  @override
  void initState() {
    super.initState();
    selectedValueNotifier = ValueNotifier<VcoreDropdownModel?>(
      widget.items.firstWhereOrNull(
        (item) => item.guid == widget.selectedGuid,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant VcoreDropdown2SelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGuid != widget.selectedGuid ||
        oldWidget.items != widget.items) {
      selectedValueNotifier.value = widget.items.firstWhereOrNull(
        (item) => item.guid == widget.selectedGuid,
      );
    }
  }

  @override
  void dispose() {
    selectedValueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dropdownBorder),
        ),
        child: DropdownButton2<VcoreDropdownModel>(
          isExpanded: true,
          hint: Text(
            widget.hint,
            style:
                TextStyles.regular.copyWith(color: Theme.of(context).hintColor),
          ),
          underline: Divider(
            color: Theme.of(context).hintColor,
          ),
          dropdownStyleData: const DropdownStyleData(
            maxHeight: 300,
            padding: EdgeInsets.symmetric(vertical: 6),
          ),
          items: widget.items
              .map(
                (VcoreDropdownModel item) =>
                    DropdownItem<VcoreDropdownModel>(
                  value: item,
                  height: 40,
                  child: Text(
                    item.text,
                    style: TextStyles.regular,
                    maxLines: 3,
                  ),
                ),
              )
              .toList(),
          valueListenable: selectedValueNotifier,
          onChanged: (VcoreDropdownModel? value) {
            if (widget.onSelected != null && value != null) {
              widget.onSelected!(value);
            }
            selectedValueNotifier.value = value;
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            width: 140,
          ),
          menuItemStyleData: const MenuItemStyleData(),
          iconStyleData:
              IconStyleData(icon: svgAsset('assets/images/ic_dropdown.svg')),
        ),
      ),
    );
  }
}
