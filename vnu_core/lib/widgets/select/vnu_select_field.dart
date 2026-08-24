import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/widgets/field/vnu_readonly_field.dart';

/// Unified select field surface.
///
/// P2V2 keeps the selected value on one stable-height line. If it is wider
/// than the field, the text itself can be dragged horizontally to read the
/// remainder while the dropdown icon stays fixed.
class VnuSelectField extends StatelessWidget {
  const VnuSelectField({
    super.key,
    required this.displayText,
    required this.placeholder,
    this.label,
    this.onTap,
    this.enabled = true,
    this.loading = false,
    this.errorText,
    this.requiredField = false,
    this.guideTargetId,
    this.leading,
    this.maxLines = 1,
    this.margin,
    this.compact = false,
  });

  final String? label;
  final String displayText;
  final String placeholder;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  final String? errorText;
  final bool requiredField;
  final String? guideTargetId;
  final Widget? leading;

  /// Kept for source compatibility with early P2 call sites.
  /// P2V2 intentionally renders selected values on one horizontal line.
  final int maxLines;

  final EdgeInsetsGeometry? margin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return VnuReadOnlyField(
      label: label,
      displayText: displayText,
      placeholder: placeholder,
      onTap: loading ? null : onTap,
      enabled: enabled,
      errorText: errorText,
      requiredField: requiredField,
      guideTargetId: guideTargetId,
      leading: leading,
      margin: margin,
      compact: compact,
      trailing: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.greenAccent,
                ),
              ),
            )
          : Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: enabled ? AppColors.greenAccent : AppColors.textHint,
            ),
    );
  }
}
