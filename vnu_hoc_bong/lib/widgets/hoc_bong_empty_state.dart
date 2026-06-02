import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class HocBongEmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onRetry;

  const HocBongEmptyState({super.key, required this.title, this.description, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: AppFontSizes.large, fontWeight: FontWeight.w700)),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
            ]
          ],
        ),
      ),
    );
  }
}
