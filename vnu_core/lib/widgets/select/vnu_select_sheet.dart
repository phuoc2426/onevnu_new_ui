import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_select_theme.dart';

class VnuSelectSheet {
  VnuSelectSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder bodyBuilder,
    String? subtitle,
    Widget? footer,
    bool showBack = false,
    VoidCallback? onBack,
    bool showClose = true,
    bool isDismissible = true,
    bool enableDrag = true,
    double maxHeightFactor = VnuSelectTheme.maxSheetHeightFactor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return VnuSelectSheetFrame(
          title: title,
          subtitle: subtitle,
          showBack: showBack,
          onBack: onBack,
          showClose: showClose,
          footer: footer,
          maxHeightFactor: maxHeightFactor,
          child: bodyBuilder(sheetContext),
        );
      },
    );
  }
}

/// Shared visual shell for every select behavior.
class VnuSelectSheetFrame extends StatelessWidget {
  const VnuSelectSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.showBack = false,
    this.onBack,
    this.showClose = true,
    this.maxHeightFactor = VnuSelectTheme.maxSheetHeightFactor,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showClose;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * maxHeightFactor),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VnuSelectTheme.sheetRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8DCE1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBack)
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyles.bold.copyWith(
                            fontSize: AppFontSizes.large,
                            color: AppColors.textTitle,
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.small,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(child: child),
            if (footer != null) ...[
              const Divider(height: 1, color: AppColors.divider),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
