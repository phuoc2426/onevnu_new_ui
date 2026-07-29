import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:path/path.dart' as p;
import 'package:vnu_core/common/app_text_styles.dart';
import 'dart:io';
import 'package:vnu_core/models/student_info_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; // thêm dòng này
import 'package:intl/intl.dart';
class DRStep4ReviewScreen extends StatefulWidget {
  const DRStep4ReviewScreen({super.key});

  @override
  State<DRStep4ReviewScreen> createState() => DRStep4ReviewScreenState();


}

class DRStep4ReviewScreenState extends State<DRStep4ReviewScreen> {
  bool _isCommitted = true;
  bool get isCommitted => _isCommitted;
  @override
  void initState() {
    super.initState();
    _loadApplicantCacheIfNeeded(); // ← gọi khi khởi tạo
  }

  // ========== THÊM TOÀN BỘ HÀM NÀY ==========
  Future<void> _loadApplicantCacheIfNeeded() async {
    // Chỉ áp dụng khi chưa có sinh viên chính thống (thí sinh)
    if (Globals().thongTinSinhVienModel.value != null) return;

    final prefs = await SharedPreferences.getInstance();
    final cccd = prefs.getString('applicant_cccd');
    if (cccd == null || cccd.isEmpty) return;

    final fullName = prefs.getString('applicant_fullname') ?? '';
    final email = prefs.getString('applicant_email') ?? '';

    final cubit = context.read<DormitoryRegistrationCubit>();
    final dob = prefs.getString('applicant_dob');
    if (cubit.tempDOB == null || cubit.tempDOB!.isEmpty) {
      cubit.tempDOB = dob;
    }
    // Đồng bộ vào cubit (phòng trường hợp chưa qua step 3)
    if (cubit.tempFullName == null || cubit.tempFullName!.isEmpty) {
      cubit.tempFullName = fullName;
    }
    if (cubit.tempCccd == null || cubit.tempCccd!.isEmpty) {
      cubit.tempCccd = cccd;
    }
    if (cubit.tempEmail == null || cubit.tempEmail!.isEmpty) {
      cubit.tempEmail = email;
    }

    // Tạo StudentInfoModel giả để Globals không null
    final fakeStudent = StudentInfoModel(
      hoVaTen: fullName,
      soCmtCccd: cccd,
      email: email,
      // Các trường khác có thể null hoặc để mặc định
    );

    Globals().thongTinSinhVienModel.value = fakeStudent;

    if (mounted) setState(() {});
  }
  // =============================================

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DormitoryRegistrationCubit>();
    final student = Globals().thongTinSinhVienModel.value;

    final periodName = cubit.selectedPeriod?.name ?? '-';
    final dormName = cubit.selectedDormitory?.name ?? '-';
    final String priorityName = cubit.selectedPriorityObjectNames.isEmpty
        ? 'Không có'
        : cubit.selectedPriorityObjectNames;
    String dobDisplay = '-';
    final rawDob = cubit.tempDOB ??
        (student?.ngaySinh != null
            ? DateFormat('yyyy-MM-dd').format(student!.ngaySinh!)
            : null);
    if (rawDob != null && rawDob.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawDob);
        dobDisplay = DateFormat('dd/MM/yyyy').format(parsed);
      } catch (_) {
        dobDisplay = rawDob;
      }
    }
    final bool hasSelectedDocuments =
        cubit.cccdFrontFile != null ||
        cubit.cccdFrontAttachment != null ||
        cubit.cccdBackFile != null ||
        cubit.cccdBackAttachment != null ||
        cubit.proofFiles.isNotEmpty ||
        cubit.proofAttachments.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thông tin đăng ký
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE3E6EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8EF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, color: Color(0xFF078B3E), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Thông tin đăng ký',
                        style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Đợt đăng ký', periodName),
                  _buildSummaryRow('Ký túc xá', dormName),
                  _buildSummaryRow('Đối tượng ưu tiên', priorityName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 2. Thông tin sinh viên
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE3E6EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8EF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, color: Color(0xFF078B3E), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Thông tin sinh viên',
                        style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Mã SV', student?.maSinhVien ?? '-'),
                  _buildSummaryRow('Họ tên', student?.hoVaTen ?? '-'),
                  _buildSummaryRow('Ngày sinh', dobDisplay),
                  _buildSummaryRow('Lớp', Globals().lopDaoTaoModel.value?.ten ?? '-'),
                  _buildSummaryRow('Ngành', Globals().lopDaoTaoModel.value?.ten ?? '-'),
                  _buildSummaryRow('SĐT', cubit.tempPhone ?? '-'),
                  _buildSummaryRow('Email', cubit.tempEmail ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 4. Lý do đăng ký
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE3E6EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8EF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_note_outlined, color: Color(0xFF078B3E), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Lý do đăng ký',
                        style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cubit.tempReason == null || cubit.tempReason!.isEmpty
                        ? 'Chưa nhập lý do.'
                        : cubit.tempReason!,
                    style: const TextStyle(
                      fontSize: AppFontSizes.small,
                      color: Color(0xFF1F2329),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE3E6EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: Color(0xFF078B3E),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ảnh và minh chứng đã chọn',
                        style: TextStyle(
                          fontSize: AppFontSizes.font11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!hasSelectedDocuments)
                    const Text(
                      'Chưa có ảnh hoặc tệp minh chứng.',
                      style: TextStyle(color: Color(0xFF666B75)),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (cubit.cccdFrontFile != null)
                          _buildLocalImagePreview(
                            cubit.cccdFrontFile!,
                            label: 'CCCD mặt trước',
                          )
                        else if (cubit.cccdFrontAttachment != null)
                          _buildUploadedFileTile(
                            label: 'CCCD mặt trước',
                            fileName: cubit.cccdFrontAttachment!.name ??
                                'CCCD_Mặt_Trước.jpg',
                          ),
                        if (cubit.cccdBackFile != null)
                          _buildLocalImagePreview(
                            cubit.cccdBackFile!,
                            label: 'CCCD mặt sau',
                          )
                        else if (cubit.cccdBackAttachment != null)
                          _buildUploadedFileTile(
                            label: 'CCCD mặt sau',
                            fileName: cubit.cccdBackAttachment!.name ??
                                'CCCD_Mặt_Sau.jpg',
                          ),
                        ...cubit.proofFiles.map(
                          (File file) => _buildLocalImagePreview(
                            file,
                            label: 'Giấy tờ ưu tiên',
                          ),
                        ),
                        ...cubit.proofAttachments.map(
                          (attachment) => _buildUploadedFileTile(
                            label: 'Giấy tờ ưu tiên',
                            fileName: attachment.name ?? 'Tệp minh chứng',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ready banner
          Container(
            width: double.infinity,
            height: 51,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDF9F0), Color(0xFFE8F7EC)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: Color(0xFF078B3E), size: 20),
                SizedBox(width: 8),
                Text(
                  'Hồ sơ đã đầy đủ và sẵn sàng gửi',
                  style: TextStyle(
                    color: Color(0xFF078B3E),
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Commitment checkbox
          Row(
            children: [
              Checkbox(
                value: _isCommitted,
                activeColor: const Color(0xFF078B3E),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _isCommitted = val;
                    });
                  }
                },
              ),
              const Expanded(
                child: Text(
                  'Tôi cam kết thông tin cung cấp là chính xác',
                  style: TextStyle(fontSize: AppFontSizes.font11, color: Color(0xFF111318), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF666B75), fontSize: AppFontSizes.small),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111318),
                fontSize: AppFontSizes.small,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalImagePreview(
    File file, {
    required String label,
  }) {
    final String fileName = p.basename(file.path);

    return SizedBox(
      width: 128,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showImagePreview(file, title: label),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFCFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3E6EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.file(
                  file,
                  width: double.infinity,
                  height: 92,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 92,
                    color: const Color(0xFFF0F2F5),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF8A9099),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.font11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111318),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.extraSmall,
                  color: Color(0xFF666B75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedFileTile({
    required String label,
    required String fileName,
  }) {
    return Container(
      width: 128,
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E6EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(
              Icons.description_outlined,
              size: 34,
              color: Color(0xFF078B3E),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSizes.font11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111318),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSizes.extraSmall,
              color: Color(0xFF666B75),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePreview(
    File file, {
    String? title,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black87,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5,
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Không thể hiển thị ảnh',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (title != null && title.trim().isNotEmpty)
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 72,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSizes.mediumSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}