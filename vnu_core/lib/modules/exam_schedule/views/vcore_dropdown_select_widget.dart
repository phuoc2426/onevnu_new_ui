import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

/// Legacy compatibility wrapper.
///
/// P2 keeps the public constructor so existing modules do not need a risky
/// big-bang migration, while the rendering/interaction is delegated to the
/// unified VNU Select System.
@Deprecated('Use VnuSingleSelect<String> from vnu_core/widgets/select/vnu_select.dart')
class VcoreDropdownSelectWidget<T> extends StatelessWidget {
  const VcoreDropdownSelectWidget({
    super.key,
    required this.items,
    required this.hint,
    required this.value,
    this.onSelected,
  });

  final List<String> items;
  final String hint;
  final String? value;
  final void Function(String value)? onSelected;

  @override
  Widget build(BuildContext context) {
    return VnuSingleSelect<String>(
      value: items.contains(value) ? value : null,
      hintText: hint,
      sheetTitle: hint,
      items: [
        for (final item in items)
          VnuSelectItem<String>(value: item, label: item),
      ],
      onChanged: (selected) {
        if (selected != null) onSelected?.call(selected);
      },
      compact: true,
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

@Deprecated('Use VnuSingleSelect<T> from vnu_core/widgets/select/vnu_select.dart')
class VcoreDropdown2SelectWidget extends StatelessWidget {
  const VcoreDropdown2SelectWidget({
    super.key,
    required this.items,
    required this.hint,
    required this.selectedGuid,
    this.onSelected,
  });

  final List<VcoreDropdownModel> items;
  final String hint;
  final String? selectedGuid;
  final void Function(VcoreDropdownModel value)? onSelected;

  VcoreDropdownModel? _selected() {
    final guid = selectedGuid;
    if (guid == null) return null;
    for (final item in items) {
      if (item.guid == guid) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return VnuSingleSelect<VcoreDropdownModel>(
      value: _selected(),
      hintText: hint,
      sheetTitle: hint,
      items: [
        for (final item in items)
          VnuSelectItem<VcoreDropdownModel>(
            value: item,
            label: item.text,
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onSelected?.call(selected);
      },
      compact: true,
    );
  }
}
