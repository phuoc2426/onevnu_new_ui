import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_select_theme.dart';

class VnuSelectOptionTile extends StatelessWidget {
  const VnuSelectOptionTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.enabled = true,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final effectiveTrailing = trailing ??
        (selected
            ? const Icon(
                Icons.check_rounded,
                color: AppColors.greenAccent,
                size: 21,
              )
            : null);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(VnuSelectTheme.optionRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: VnuSelectTheme.optionMinHeight,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? VnuSelectTheme.selectedBackground
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(VnuSelectTheme.optionRadius),
                border: Border.all(
                  color: selected
                      ? AppColors.greenAccent.withOpacity(0.32)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          softWrap: true,
                          style: TextStyles.semiBold.copyWith(
                            fontSize: AppFontSizes.mediumSmall,
                            color: enabled
                                ? (selected
                                    ? AppColors.greenAccentDark
                                    : AppColors.textPrimary)
                                : AppColors.textHint,
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            softWrap: true,
                            style: TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.small,
                              color: enabled
                                  ? AppColors.textSecondary
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (effectiveTrailing != null) ...[
                    const SizedBox(width: 10),
                    effectiveTrailing,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
