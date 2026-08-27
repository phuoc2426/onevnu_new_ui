import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_field_decoration.dart';
import 'vnu_field_metrics.dart';
import 'vnu_field_shell.dart';

/// Unified editable floating field for OneVNU forms.
///
/// Single-line values use Flutter's native horizontal editing scroll. Labels
/// start inside an empty field and float to the outline on focus/value.
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
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
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
    this.style,
    this.cursorColor,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.scrollPhysics,
    this.textAlignVertical,
    this.helperText,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final bool enabled;
  final bool readOnly;
  final bool requiredField;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
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
  final TextStyle? style;
  final Color? cursorColor;
  final bool autocorrect;
  final bool enableSuggestions;
  final ScrollPhysics? scrollPhysics;
  final TextAlignVertical? textAlignVertical;
  final String? helperText;

  bool get _isSingleLine => maxLines == 1;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.trim().isNotEmpty;
    final minHeight = VnuFieldMetrics.minHeightFor(context, compact: compact);

    final Widget field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      onTap: onTap,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: _isSingleLine ? 1 : minLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      textAlignVertical: textAlignVertical ??
          (_isSingleLine ? TextAlignVertical.center : null),
      scrollPhysics: scrollPhysics ?? const ClampingScrollPhysics(),
      style: style ??
          TextStyles.regular.copyWith(
            fontSize: AppFontSizes.mediumSmall,
            color: enabled && !readOnly
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
      cursorColor: cursorColor ?? AppColors.greenAccent,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      decoration: VnuFieldDecoration.build(
        label: label,
        hintText: hintText,
        requiredField: requiredField,
        enabled: enabled,
        readOnly: readOnly,
        hasError: hasError,
        prefixIcon: leading,
        suffixIcon: trailing,
        compact: compact,
        multiline: !_isSingleLine,
        helperText: helperText,
      ).copyWith(
        constraints: _isSingleLine ? BoxConstraints(minHeight: minHeight) : null,
      ),
    );

    return VnuFieldShell(
      errorText: errorText,
      enabled: enabled,
      margin: margin,
      guideTargetId: guideTargetId,
      child: field,
    );
  }
}

/// Compatibility adapter for legacy feature code that still constructed a
/// raw [TextField]. It deliberately discards per-screen border/fill styling and
/// maps the old decoration into OneVNU's shared floating-field contract.
///
/// This keeps behaviour such as controller/focus/keyboard callbacks while
/// making legacy inputs visually consistent without maintaining dozens of
/// bespoke [InputDecoration] implementations.
@Deprecated('Use VnuTextField directly for new code')
class VnuFloatingTextFieldAdapter extends StatelessWidget {
  const VnuFloatingTextFieldAdapter({
    super.key,
    this.controller,
    this.focusNode,
    this.style,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.decoration = const InputDecoration(),
    this.inputFormatters,
    this.textInputAction,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.cursorColor,
    this.textAlignVertical,
    this.scrollPhysics,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final InputDecoration decoration;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool enableSuggestions;
  final Color? cursorColor;
  final TextAlignVertical? textAlignVertical;
  final ScrollPhysics? scrollPhysics;

  @override
  Widget build(BuildContext context) {
    final explicitLabel = decoration.labelText?.trim();
    final legacyHint = decoration.hintText?.trim();
    final label = (explicitLabel != null && explicitLabel.isNotEmpty)
        ? explicitLabel
        : legacyHint;
    final hint = (explicitLabel != null && explicitLabel.isNotEmpty)
        ? legacyHint
        : null;

    return VnuTextField(
      controller: controller,
      focusNode: focusNode,
      style: style,
      readOnly: readOnly,
      enabled: enabled,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      obscureText: obscureText,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      label: label,
      hintText: hint,
      leading: decoration.prefixIcon,
      trailing: decoration.suffixIcon,
      helperText: decoration.helperText,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      cursorColor: cursorColor,
      textAlignVertical: textAlignVertical,
      scrollPhysics: scrollPhysics,
    );
  }
}

