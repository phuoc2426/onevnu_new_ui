import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/app_colors.dart';

import '../common/hoc_bong_status.dart';
import '../cubit/hoc_bong_ho_so_cubit.dart';
import '../cubit/hoc_bong_states.dart';
import '../repository/hoc_bong_repository.dart';
import '../widgets/hoc_bong_empty_state.dart';
import '../widgets/hoc_bong_screen_shell.dart';
import '../widgets/hoc_bong_status_chip.dart';
import 'hoc_bong_file_preview_screen.dart';

class HocBongApplicationDetailScreen extends StatefulWidget {
  final int hoSoId;
  final HocBongRepository repository;

  const HocBongApplicationDetailScreen({super.key, required this.hoSoId, required this.repository});

  @override
  State<HocBongApplicationDetailScreen> createState() => _HocBongApplicationDetailScreenState();
}

class _HocBongApplicationDetailScreenState extends State<HocBongApplicationDetailScreen> {
  late final HocBongHoSoCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HocBongHoSoCubit(widget.repository)..loadDetail(widget.hoSoId);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HocBongScreenShell(
      title: 'Chi tiết hồ sơ',
      body: BlocBuilder<HocBongHoSoCubit, HocBongHoSoState>(
        bloc: cubit,
        builder: (context, state) {
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
              ),
            );
          }
          final detail = state.detail;
          if (detail == null) {
            return HocBongEmptyState(
              title: state.error ?? 'Không tìm thấy hồ sơ',
              onRetry: () => cubit.loadDetail(widget.hoSoId),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.tenHocBong ?? 'Hồ sơ học bổng', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      HocBongStatusChip(
                        status: detail.trangThai,
                        label: detail.trangThaiText ?? HocBongStatusText.application(detail.trangThai),
                      ),
                      if ((detail.phanHoiAdmin ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Phản hồi: ${detail.phanHoiAdmin!}'),
                      ],
                      if ((detail.lyDoTuChoi ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Lý do từ chối: ${detail.lyDoTuChoi!}', style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Thông tin đã nộp',
                child: detail.duLieuDangKy.isEmpty
                    ? const Text('Không có dữ liệu')
                    : Column(
                        children: detail.duLieuDangKy.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: Text(e.key, style: TextStyle(color: Colors.grey.shade700))),
                                    Expanded(flex: 3, child: Text(e.value?.toString() ?? '')),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Minh chứng',
                child: detail.files.isEmpty
                    ? const Text('Chưa có minh chứng')
                    : Column(
                        children: detail.files.map((f) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.greenAccent),
                            title: Text(f.tenMinhChung ?? f.tenFileHienThi ?? 'Minh chứng'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HocBongStatusChip(
                                  status: f.trangThaiKiemTra,
                                  label: HocBongStatusText.fileCheck(f.trangThaiKiemTra),
                                ),
                                if ((f.ghiChuKiemTra ?? '').isNotEmpty) Text(f.ghiChuKiemTra!),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: f.fileId == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HocBongFilePreviewScreen(
                                          fileId: f.fileId!,
                                          repository: widget.repository,
                                          title: f.tenMinhChung,
                                        ),
                                      ),
                                    ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
