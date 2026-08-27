import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/guide/widgets/app_guide_anchor.dart';

/// Outer shell for OneVNU fields.
///
/// Labels are rendered by the field's InputDecoration so every editable,
/// select, date and read-only control follows the same floating-label contract.
/// This shell only owns margin, guide anchoring and the optional external error
/// message used by non-FormField controls.
class VnuFieldShell extends StatelessWidget {
  const VnuFieldShell({
    super.key,
    required this.child,
    this.label,
    this.requiredField = false,
    this.errorText,
    this.enabled = true,
    this.margin,
    this.guideTargetId,
  });

  /// Kept for source compatibility. Labels are rendered inside the field.
  final String? label;
  final bool requiredField;
  final Widget child;
  final String? errorText;
  final bool enabled;
  final EdgeInsetsGeometry? margin;
  final String? guideTargetId;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    Widget result = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          child,
          if (hasError) ...<Widget>[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                errorText!,
                softWrap: true,
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.small,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final targetId = guideTargetId?.trim();
    if (targetId == null || targetId.isEmpty) return result;
    return AppGuideAnchor(id: targetId, child: result);
  }
}
