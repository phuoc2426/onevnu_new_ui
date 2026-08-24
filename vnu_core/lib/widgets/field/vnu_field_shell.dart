import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/guide/widgets/app_guide_anchor.dart';

/// Shared label / required marker / validation-message shell for OneVNU fields.
///
/// Labels and errors are allowed to wrap. The input surface inside [child]
/// keeps its own stable height, so a long label does not make neighbouring
/// input boxes themselves inconsistent.
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

  final Widget child;
  final String? label;
  final bool requiredField;
  final String? errorText;
  final bool enabled;
  final EdgeInsetsGeometry? margin;
  final String? guideTargetId;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.trim().isNotEmpty;
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    Widget result = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLabel) ...[
            Text.rich(
              TextSpan(
                text: label,
                style: TextStyles.semiBold.copyWith(
                  fontSize: AppFontSizes.mediumSmall,
                  color: enabled ? AppColors.textPrimary : AppColors.textHint,
                ),
                children: requiredField
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ]
                    : const [],
              ),
              softWrap: true,
            ),
            const SizedBox(height: 7),
          ],
          child,
          if (hasError) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 2),
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
