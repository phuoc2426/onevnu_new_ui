import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

/// Compatibility wrapper for the dormitory module.
///
/// P2 moves all select rendering/interaction into vnu_core so dormitory no
/// longer owns a separate bottom-sheet design. Existing call sites can keep
/// using NtCustomDropdown during the migration window.
@Deprecated('Use VnuSingleSelect<T> from vnu_core/widgets/select/vnu_select.dart')
class NtCustomDropdown<T> extends StatelessWidget {
  const NtCustomDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.itemAsString,
    this.itemAsSubtitle,
    required this.onChanged,
    this.validator,
    this.clearable = false,
    this.clearableText,
  });

  final String label;
  final String hintText;
  final T? value;
  final List<T> items;
  final String Function(T) itemAsString;
  final String Function(T)? itemAsSubtitle;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool clearable;
  final String? clearableText;

  @override
  Widget build(BuildContext context) {
    return VnuSingleSelect<T>(
      label: label,
      value: value,
      hintText: hintText,
      sheetTitle: label,
      validator: validator,
      clearable: clearable,
      clearLabel: clearableText ?? 'Không chọn',
      items: [
        for (final item in items)
          VnuSelectItem<T>(
            value: item,
            label: itemAsString(item),
            subtitle: itemAsSubtitle?.call(item),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
