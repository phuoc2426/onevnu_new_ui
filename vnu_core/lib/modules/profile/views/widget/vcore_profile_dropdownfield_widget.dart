import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

/// Legacy profile adapter backed by the shared P2/P2V2 select field.
@Deprecated('Use VnuSingleSelect<String> from vnu_core/widgets/select/vnu_select.dart')
class VcoreProfileDropdownfieldWidget extends StatelessWidget {
  const VcoreProfileDropdownfieldWidget({
    super.key,
    required this.title,
    required this.hintText,
    this.value,
    this.isRequired = false,
    required this.items,
    this.onSelected,
  });

  final String title;
  final String hintText;
  final String? value;
  final bool isRequired;
  final List<String> items;
  final void Function(String value)? onSelected;

  @override
  Widget build(BuildContext context) {
    return VnuSingleSelect<String>(
      label: title,
      value: items.contains(value) ? value : null,
      hintText: hintText,
      sheetTitle: title,
      requiredField: isRequired,
      items: [
        for (final item in items)
          VnuSelectItem<String>(value: item, label: item),
      ],
      onChanged: (selected) {
        if (selected != null) onSelected?.call(selected);
      },
    );
  }
}
