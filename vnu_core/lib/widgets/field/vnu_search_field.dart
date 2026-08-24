import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';

import 'vnu_text_field.dart';

/// Shared compact search input.
///
/// It is always single-line, so long queries use Flutter's native horizontal
/// scrolling instead of wrapping and changing the control height.
class VnuSearchField extends StatelessWidget {
  const VnuSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return VnuTextField(
      controller: controller,
      hintText: hintText,
      maxLines: 1,
      compact: true,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      leading: const Icon(
        Icons.search_rounded,
        size: 20,
        color: AppColors.textHint,
      ),
      trailing: trailing,
    );
  }
}
