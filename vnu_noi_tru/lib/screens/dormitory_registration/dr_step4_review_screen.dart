import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:path/path.dart' as p;
import 'package:vnu_core/common/app_text_styles.dart';
import 'dart:io';

class DRStep4ReviewScreen extends StatefulWidget {
  const DRStep4ReviewScreen({super.key});

  @override
  State<DRStep4ReviewScreen> createState() => DRStep4ReviewScreenState();


}

class DRStep4ReviewScreenState extends State<DRStep4ReviewScreen> {
  bool _isCommitted = true;

  bool get isCommitted => _isCommitted;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DormitoryRegistrationCubit>();
    final student = Globals().thongTinSinhVienModel.value;

    final periodName = cubit.selectedPeriod?.name ?? '-';
    final dormName = cubit.selectedDormitory?.name ?? '-';
    final roomName = cubit.selectedRoomType?.name ?? '-';
    final priorityName = cubit.selectedPriorityObject?.name ?? 'Không có';

    // List of files to display as chips (local files + uploaded files)
    final List<String> fileNames = [];
    if (cubit.cccdFrontFile != null) {
      fileNames.add(p.basename(cubit.cccdFrontFile!.path));
    } else if (cubit.cccdFrontAttachment != null) {
      fileNames.add(cubit.cccdFrontAttachment!.name ?? 'CCCD_Mặt_Trước.jpg');
    }

    if (cubit.cccdBackFile != null) {
      fileNames.add(p.basename(cubit.cccdBackFile!.path));
    } else if (cubit.cccdBackAttachment != null) {
      fileNames.add(cubit.cccdBackAttachment!.name ?? 'CCCD_Mặt_Sau.jpg');
    }

    for (var file in cubit.proofFiles) {
      fileNames.add(p.basename(file.path));
    }
    for (var doc in cubit.proofAttachments) {
      if (doc.name != null) {
        fileNames.add(doc.name!);
      }
    }

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
                  _buildSummaryRow('Loại phòng', roomName),
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
                  _buildSummaryRow('Lớp', Globals().lopDaoTaoModel.value?.ten ?? '-'),
                  _buildSummaryRow('Ngành', Globals().lopDaoTaoModel.value?.ten ?? '-'),
                  _buildSummaryRow('SĐT', cubit.tempPhone ?? '-'),
                  _buildSummaryRow('Email', cubit.tempEmail ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 3. Minh chứng
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
                        child: const Icon(Icons.description_outlined, color: Color(0xFF078B3E), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Minh chứng',
                        style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (fileNames.isEmpty)
                    const Text('Chưa có tệp minh chứng nào', style: TextStyle(color: Color(0xFF666B75), fontSize: AppFontSizes.medium))
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: fileNames.map((name) {
                        return Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 64,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFCFD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE3E6EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.description_outlined, color: Color(0xFF078B3E), size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: AppFontSizes.font11, color: Color(0xFF111318), fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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
                      Icon(Icons.image_outlined, color: Color(0xFF078B3E), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Minh chứng đã chọn',
                        style: TextStyle(
                          fontSize: AppFontSizes.font11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (cubit.proofFiles.isEmpty && cubit.proofAttachments.isEmpty)
                    const Text(
                      'Chưa có minh chứng bổ sung.',
                      style: TextStyle(color: Color(0xFF666B75)),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...cubit.proofFiles.map(_buildLocalImagePreview),
                        ...cubit.proofAttachments.map(
                              (e) => Chip(
                            avatar: const Icon(Icons.description_outlined, size: 16),
                            label: Text(e.name ?? 'Tệp minh chứng'),
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

  Widget _buildLocalImagePreview(File file) {
    return GestureDetector(
      onTap: () => _showImagePreview(file),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showImagePreview(File file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InteractiveViewer(
            child: Image.file(
              file,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
