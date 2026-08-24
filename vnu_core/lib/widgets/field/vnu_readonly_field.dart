import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_field_metrics.dart';
import 'vnu_field_shell.dart';
import 'vnu_horizontal_readable_value.dart';

/// Shared one-line read-only/value field.
///
/// Long values stay on one line and can be dragged horizontally. Leading and
/// trailing widgets stay fixed.
class VnuReadOnlyField extends StatelessWidget {
  const VnuReadOnlyField({
    super.key,
    required this.displayText,
    required this.placeholder,
    this.label,
    this.onTap,
    this.enabled = true,
    this.errorText,
    this.requiredField = false,
    this.guideTargetId,
    this.leading,
    this.trailing,
    this.margin,
    this.compact = false,
    this.hasValue,
  });

  final String? label;
  final String displayText;
  final String placeholder;
  final VoidCallback? onTap;
  final bool enabled;
  final String? errorText;
  final bool requiredField;
  final String? guideTargetId;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final bool compact;
  final bool? hasValue;

  @override
  Widget build(BuildContext context) {
    final effectiveHasValue = hasValue ?? displayText.trim().isNotEmpty;
    final hasError = errorText != null && errorText!.trim().isNotEmpty;
    final shownText = effectiveHasValue ? displayText : placeholder;
    final textStyle = TextStyles.medium.copyWith(
      fontSize: AppFontSizes.mediumSmall,
      color: !enabled
          ? AppColors.textHint
          : effectiveHasValue
              ? AppColors.textPrimary
              : AppColors.textHint,
    );

    final surface = Semantics(
      button: onTap != null,
      enabled: enabled,
      label: [label, shownText]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(', '),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            constraints: BoxConstraints(
              minHeight: VnuFieldMetrics.minHeightFor(
                context,
                compact: compact,
              ),
            ),
            padding: VnuFieldMetrics.contentPadding,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF5F6F7),
              borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : effectiveHasValue
                        ? AppColors.greenAccent.withOpacity(0.55)
                        : AppColors.border,
                width: hasError || effectiveHasValue ? 1.35 : 1,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: VnuHorizontalReadableValue(
                    text: shownText,
                    style: textStyle,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return VnuFieldShell(
      label: label,
      requiredField: requiredField,
      errorText: errorText,
      enabled: enabled,
      margin: margin,
      guideTargetId: guideTargetId,
      child: surface,
    );
  }
}
