import 'package:flutter/material.dart';

import '../common/hoc_bong_status.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class HocBongStatusChip extends StatelessWidget {
  final String? status;
  final String label;

  const HocBongStatusChip({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty ||
        label == 'HoatDong' ||
        label == 'Hoạt động' ||
        label == 'ACTIVE') {
      return const SizedBox.shrink();
    }
    final color = HocBongStatusText.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: AppFontSizes.small, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
