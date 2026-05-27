import 'package:flutter/material.dart';

import '../common/hoc_bong_date_utils.dart';
import '../common/hoc_bong_status.dart';
import '../models/hoc_bong_models.dart';

class HocBongApplicationTimeline extends StatelessWidget {
  final List<HocBongHistoryModel> history;

  const HocBongApplicationTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text('Chưa có lịch sử xử lý hồ sơ.');
    }
    return Column(
      children: history.map((item) {
        final color = HocBongStatusText.color(item.trangThaiMoi);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.hanhDong ?? HocBongStatusText.application(item.trangThaiMoi), style: const TextStyle(fontWeight: FontWeight.w700)),
                  if ((item.noiDung ?? '').isNotEmpty) Text(item.noiDung!),
                  Text(HocBongDateUtils.formatDateTime(item.created), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
