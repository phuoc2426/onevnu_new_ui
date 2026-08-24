import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_field_metrics.dart';
import 'vnu_field_shell.dart';

/// Unified editable text field for OneVNU forms.
///
/// Single-line fields rely on Flutter's native horizontal text scrolling, so
/// long input never wraps and can be dragged/cursor-scrolled to read/edit the
/// rest. Multiline fields intentionally wrap and scroll vertically.
class VnuTextField extends StatelessWidget {
  const VnuTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.enabled = true,
    this.readOnly = false,
    this.requiredField = false,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.leading,
    this.trailing,
    this.margin,
    this.guideTargetId,
    this.compact = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final bool enabled;
  final bool readOnly;
  final bool requiredField;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final String? guideTargetId;
  final bool compact;
  final TextCapitalization textCapitalization;

  bool get _isSingleLine => maxLines == 1;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.trim().isNotEmpty;
    final minHeight = VnuFieldMetrics.minHeightFor(
      context,
      compact: compact,
    );

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: _isSingleLine ? 1 : minLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      textAlignVertical: _isSingleLine ? TextAlignVertical.center : null,
      scrollPhysics: const ClampingScrollPhysics(),
      style: TextStyles.regular.copyWith(
        fontSize: AppFontSizes.mediumSmall,
        color: enabled && !readOnly ? AppColors.textPrimary : AppColors.textHint,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyles.regular.copyWith(
          fontSize: AppFontSizes.mediumSmall,
          color: AppColors.textHint,
        ),
        prefixIcon: leading,
        suffixIcon: trailing,
        filled: true,
        fillColor: enabled && !readOnly ? Colors.white : const Color(0xFFF5F6F7),
        isDense: true,
        constraints: _isSingleLine
            ? BoxConstraints(minHeight: minHeight)
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: _isSingleLine ? 12 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.border,
            width: hasError ? 1.35 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.greenAccent,
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        counterText: '',
      ),
    );

    return VnuFieldShell(
      label: label,
      requiredField: requiredField,
      errorText: errorText,
      enabled: enabled,
      margin: margin,
      guideTargetId: guideTargetId,
      child: field,
    );
  }
}
