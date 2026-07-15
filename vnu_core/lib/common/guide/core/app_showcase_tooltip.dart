import 'package:flutter/material.dart';

import 'app_showcase_style.dart';

class AppShowcaseTooltip extends StatelessWidget {
  const AppShowcaseTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.stepIndex,
    required this.totalSteps,
    required this.style,
    required this.onSkip,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  final String title;
  final String description;
  final IconData icon;
  final int stepIndex;
  final int totalSteps;
  final AppShowcaseStyle style;

  final VoidCallback onSkip;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  bool get isLast => stepIndex >= totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: style.tooltipWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(style.tooltipRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: style.titleColor,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (style.showIcon)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: style.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: style.primaryColor,
                        size: 22,
                      ),
                    ),
                  if (style.showIcon) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        color: style.titleColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  if (style.showProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: style.badgeBackgroundColor ??
                            style.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${stepIndex + 1}/$totalSteps',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: style.badgeTextColor ?? style.primaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: style.descriptionColor,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (stepIndex > 0)
                    TextButton(
                      onPressed: onPrevious,
                      style: TextButton.styleFrom(
                        foregroundColor: style.primaryColor,
                      ),
                      child: const Text(
                        'Trước',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLast ? onFinish : onNext,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: style.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Hoàn tất' : 'Tiếp tục',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
