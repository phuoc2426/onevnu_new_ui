import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

@Deprecated('Use VnuSelectField from vnu_core/widgets/select/vnu_select.dart')
class NtContainerDropboxWidget extends StatelessWidget {
  const NtContainerDropboxWidget({
    super.key,
    required this.title,
    this.onSelecte,
    this.activeSelect = false,
    required this.value,
  });

  final String title;
  final String? value;
  final VoidCallback? onSelecte;
  final bool? activeSelect;

  @override
  Widget build(BuildContext context) {
    return VnuSelectField(
      label: title,
      displayText: value ?? '',
      placeholder: 'Chọn $title',
      enabled: activeSelect == true,
      onTap: onSelecte,
    );
  }
}
