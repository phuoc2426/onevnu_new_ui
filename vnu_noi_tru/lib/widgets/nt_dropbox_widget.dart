import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

@Deprecated('Use VnuSingleSelect<String> from vnu_core/widgets/select/vnu_select.dart')
class NTDropboxWidget extends StatelessWidget {
  const NTDropboxWidget({
    super.key,
    required this.title,
    required this.value,
    required this.listOption,
    this.activeSelect = false,
    this.onSelected,
  });

  final String title;
  final String? value;
  final List<String> listOption;
  final bool? activeSelect;
  final Function(String value, int index)? onSelected;

  @override
  Widget build(BuildContext context) {
    return VnuSingleSelect<String>(
      label: title,
      value: listOption.contains(value) ? value : null,
      hintText: 'Chọn $title',
      sheetTitle: title,
      enabled: activeSelect == true,
      items: [
        for (final item in listOption)
          VnuSelectItem<String>(value: item, label: item),
      ],
      onChanged: (selected) {
        if (selected == null || onSelected == null) return;
        onSelected!(selected, listOption.indexOf(selected));
      },
    );
  }
}
