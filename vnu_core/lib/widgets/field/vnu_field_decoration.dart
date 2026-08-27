import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_field_metrics.dart';

/// Single decoration contract for all OneVNU form controls.
///
/// Empty + unfocused: the label rests inside the field.
/// Focused / has value: the label floats onto the outline.
class VnuFieldDecoration {
  VnuFieldDecoration._();

  static Widget? labelWidget(
    String? label, {
    bool requiredField = false,
  }) {
    final text = label?.trim() ?? '';
    if (text.isEmpty) return null;

    return Text.rich(
      TextSpan(
        text: text,
        children: requiredField
            ? const <InlineSpan>[
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
              ]
            : const <InlineSpan>[],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static InputDecoration build({
    String? label,
    String? hintText,
    bool requiredField = false,
    bool enabled = true,
    bool readOnly = false,
    bool hasError = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool compact = false,
    bool multiline = false,
    String? helperText,
  }) {
    final Color fillColor = enabled && !readOnly
        ? Colors.white
        : const Color(0xFFF5F6F7);

    OutlineInputBorder outline(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      label: labelWidget(label, requiredField: requiredField),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: TextStyles.semiBold.copyWith(
        fontSize: AppFontSizes.small,
        height: 1.8,
        color: hasError ? AppColors.error : AppColors.greenAccent,
      ),
      labelStyle: TextStyles.regular.copyWith(
        fontSize: AppFontSizes.mediumSmall,
        color: enabled ? AppColors.textHint : AppColors.textHint,
      ),
      hintText: hintText,
      hintStyle: TextStyles.regular.copyWith(
        fontSize: AppFontSizes.mediumSmall,
        color: AppColors.textHint,
      ),
      helperText: helperText,
      alignLabelWithHint: multiline,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      // Do not force a dense layout: a floating outline label needs a little
      // vertical breathing room, otherwise parents with tight constraints
      // (notably the login glass fields) can clip the top of the label.
      isDense: false,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 12 : (multiline ? 16 : 15),
      ),
      border: outline(hasError ? AppColors.error : AppColors.border, 1),
      enabledBorder: outline(
        hasError ? AppColors.error : AppColors.border,
        hasError ? 1.35 : 1,
      ),
      focusedBorder: outline(
        hasError ? AppColors.error : AppColors.greenAccent,
        1.5,
      ),
      disabledBorder: outline(AppColors.border, 1),
      errorBorder: outline(AppColors.error, 1.35),
      focusedErrorBorder: outline(AppColors.error, 1.5),
      counterText: '',
    );
  }
}
