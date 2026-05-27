import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/app_colors.dart';

import '../common/hoc_bong_date_utils.dart';
import 'hoc_bong_file_preview_screen.dart';
import '../common/hoc_bong_status.dart';
import '../cubit/hoc_bong_detail_cubit.dart';
import '../cubit/hoc_bong_states.dart';
import '../models/hoc_bong_models.dart';
import '../repository/hoc_bong_repository.dart';
import '../widgets/hoc_bong_condition_check_list.dart';
import '../widgets/hoc_bong_empty_state.dart';
import '../widgets/hoc_bong_screen_shell.dart';
import '../widgets/hoc_bong_status_chip.dart';
import 'hoc_bong_application_detail_screen.dart';
import 'hoc_bong_register_form_screen.dart';

class HocBongDetailScreen extends StatefulWidget {
  final int hocBongId;
  final HocBongRepository repository;

  const HocBongDetailScreen({super.key, required this.hocBongId, required this.repository});

  @override
  State<HocBongDetailScreen> createState() => _HocBongDetailScreenState();
}

class _HocBongDetailScreenState extends State<HocBongDetailScreen> {
  late final HocBongDetailCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HocBongDetailCubit(widget.repository)..load(widget.hocBongId);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HocBongScreenShell(
      title: 'Chi tiết học bổng',
      body: BlocBuilder<HocBongDetailCubit, HocBongDetailState>(
        bloc: cubit,
        builder: (context, state) {
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
              ),
            );
          }
          if (state.error != null || state.detail == null) {
            return HocBongEmptyState(
              title: state.error ?? 'Không tìm thấy học bổng',
              onRetry: () => cubit.load(widget.hocBongId),
            );
          }
          final hb = state.detail!.hocBong;
          final validate = state.validateResult;
          final draft = state.draft ?? state.detail!.hoSo;
          final canRegister = validate == null || validate.result == 'PASS' || validate.result == 'NEED_MANUAL_REVIEW';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
                            Text(
                              hb.tenHocBong ?? 'Học bổng',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                HocBongStatusChip(
                                  status: hb.trangThai,
                                  label: hb.trangThaiText ?? HocBongStatusText.scholarship(hb.trangThai),
                                ),
                                if (draft?.trangThai != null)
                                  HocBongStatusChip(
                                    status: draft!.trangThai,
                                    label: HocBongStatusText.application(draft.trangThai),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(label: 'Năm học', value: '${hb.namHoc ?? '--'} ${hb.hocKy ?? ''}'.trim()),
                            _InfoRow(label: 'Hạn đăng ký', value: HocBongDateUtils.formatDate(hb.ngayKetThucDangKy)),
                            if (hb.soSuat != null) _InfoRow(label: 'Số suất', value: '${hb.soSuat}'),
                            if (hb.giaTri != null) _InfoRow(label: 'Giá trị', value: hb.giaTri == 0 ? 'Không rõ' : '${hb.giaTri} đ'),
                          ],
                        ),
                      ),
                    ),
                    HocBongConditionCheckList(result: validate),
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(top: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hb.moTaNgan != null && hb.moTaNgan!.trim().isNotEmpty) ...[
                              const Text('Mô tả ngắn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                hb.moTaNgan!,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                              ),
                              const Divider(height: 24),
                            ],
                            const Text('Nội dung chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            if (hb.noiDung != null && hb.noiDung!.trim().isNotEmpty)
                              Html(
                                data: hb.noiDung!,
                                onLinkTap: (url, attributes, element) {
                                  if (url != null) {
                                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  }
                                },
                              )
                            else
                              const Text('Chưa có nội dung chi tiết', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    if (state.detail!.files.isNotEmpty)
                      Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(top: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quyết định & Thể lệ học bổng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              ...state.detail!.files.map(
                                (file) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      if (file.fileId != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => HocBongFilePreviewScreen(
                                              fileId: file.fileId!,
                                              title: file.tenFileHienThi ?? 'Xem thể lệ',
                                              repository: widget.repository,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  file.tenFileHienThi ?? 'Tài liệu đính kèm',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                ),
                                                if (file.loaiMinhChung != null && file.loaiMinhChung!.trim().isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _getLoaiFileText(file.loaiMinhChung),
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (state.detail!.formFields.isNotEmpty)
                      Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(top: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thông tin/minh chứng cần nộp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              ...state.detail!.formFields.map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 20, color: AppColors.greenAccent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f.displayLabel,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formFieldMeta(f),
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _BottomAction(
                detail: state.detail!,
                draft: draft,
                validate: validate,
                canRegister: canRegister,
                hocBongId: widget.hocBongId,
                repository: widget.repository,
                onReload: () => cubit.load(widget.hocBongId),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final HocBongDetailModel detail;
  final HocBongHoSoModel? draft;
  final HocBongValidateResultModel? validate;
  final bool canRegister;
  final int hocBongId;
  final HocBongRepository repository;
  final VoidCallback onReload;

  const _BottomAction({
    required this.detail,
    required this.draft,
    required this.validate,
    required this.canRegister,
    required this.hocBongId,
    required this.repository,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    String label = 'Đăng ký học bổng';
    VoidCallback? action;

    final hoSo = draft;
    if (hoSo != null && hoSo.canEdit) {
      label = hoSo.trangThai == 'NEED_MORE_INFO' ? 'Bổ sung hồ sơ' : 'Tiếp tục chỉnh sửa bản nháp';
      action = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HocBongRegisterFormScreen(hocBongId: hocBongId, repository: repository)),
          ).then((_) => onReload());
    } else if (hoSo != null) {
      label = 'Xem hồ sơ đã gửi';
      action = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HocBongApplicationDetailScreen(hoSoId: hoSo.id, repository: repository)),
          );
    } else if (canRegister) {
      // Tạm thời vô hiệu hóa đăng ký học bổng
      action = null;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(canRegister || hoSo != null ? label : 'Không đủ điều kiện đăng ký'),
          ),
        ),
      ),
    );
  }
}

String _formFieldMeta(HocBongFormFieldModel f) {
  final parts = <String>[
    _kieuDuLieuText(f.kieuDuLieu),
    if (f.batBuoc) 'Bắt buộc',
    if (f.yeuCauCongChung) 'Có công chứng',
  ];
  return parts.join(' • ');
}

String _kieuDuLieuText(String kieu) {
  switch (kieu) {
    case 'FILE':
      return 'Tệp PDF';
    case 'SELECT':
      return 'Lựa chọn';
    case 'TEXTAREA':
      return 'Văn bản dài';
    case 'NUMBER':
      return 'Số';
    case 'DATE':
      return 'Ngày';
    default:
      return 'Văn bản';
  }
}

String _getLoaiFileText(String? loai) {
  switch (loai) {
    case 'THE_LE':
      return 'Thể lệ';
    case 'HUONG_DAN':
      return 'Hướng dẫn';
    case 'BIEU_MAU':
      return 'Biểu mẫu';
    case 'QUYET_DINH':
      return 'Quyết định';
    default:
      return 'Tài liệu';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
