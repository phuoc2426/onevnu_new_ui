import 'package:flutter/material.dart';

import '../common/hoc_bong_status.dart';
import '../models/hoc_bong_models.dart';
import 'hoc_bong_status_chip.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class HocBongConditionCheckList extends StatelessWidget {
  final HocBongValidateResultModel? result;

  const HocBongConditionCheckList({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const SizedBox.shrink();
    }
    final r = result!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Kết quả kiểm tra điều kiện', style: TextStyle(fontSize: AppFontSizes.large, fontWeight: FontWeight.w700))),
                HocBongStatusChip(status: r.result, label: HocBongStatusText.validate(r.result)),
              ],
            ),
            if ((r.message ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.message!, style: TextStyle(color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 10),
            ...r.checks.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: HocBongStatusText.color(r.result)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e)),
                  ],
                ),
              ),
            ),
            ...r.warnings.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF59F00)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
