import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';

import '../common/hoc_bong_date_utils.dart';
import '../common/hoc_bong_status.dart';
import '../models/hoc_bong_models.dart';
import 'hoc_bong_status_chip.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class HocBongCard extends StatelessWidget {
  final HocBongModel item;
  final VoidCallback onTap;

  const HocBongCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.tenHocBong ?? 'Học bổng',
                      style: const TextStyle(fontSize: AppFontSizes.large, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if ((item.moTaNgan ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.moTaNgan!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _Info(icon: Icons.calendar_month, text: '${item.namHoc ?? ''} ${item.hocKy ?? ''}'.trim()),
                  _Info(icon: Icons.event_available, text: 'Hạn: ${HocBongDateUtils.formatDate(item.ngayKetThucDangKy)}'),
                  if (item.soSuat != null) _Info(icon: Icons.people_alt_outlined, text: '${item.soSuat} suất'),
                  if (item.giaTri != null) _Info(icon: Icons.payments_outlined, text: item.giaTri == 0 ? 'Không rõ' : '${item.giaTri} đ'),
                ],
              ),
              if (item.ketQuaValidate != null || item.trangThaiHoSo != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (item.ketQuaValidate != null)
                      HocBongStatusChip(status: item.ketQuaValidate, label: HocBongStatusText.validate(item.ketQuaValidate)),
                    if (item.trangThaiHoSo != null)
                      HocBongStatusChip(status: item.trangThaiHoSo, label: HocBongStatusText.application(item.trangThaiHoSo)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: AppFontSizes.font12_5)),
      ],
    );
  }
}
