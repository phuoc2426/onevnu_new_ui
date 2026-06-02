import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:path/path.dart' as p;
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_noi_tru/widgets/nt_custom_dropdown.dart';

class DRStep3InfoScreen extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const DRStep3InfoScreen({super.key, required this.formKey});

  @override
  State<DRStep3InfoScreen> createState() => DRStep3InfoScreenState();
}

class DRStep3InfoScreenState extends State<DRStep3InfoScreen> {
  final _picker = ImagePicker();

  // Controllers for all form inputs
  late TextEditingController _studentCodeController;
  late TextEditingController _fullNameController;
  late TextEditingController _dobController;
  late TextEditingController _genderController;
  late TextEditingController _cccdController;
  late TextEditingController _cccdIssueDateController;
  late TextEditingController _hometownController;
  late TextEditingController _classNameController;
  late TextEditingController _majorController;
  late TextEditingController _academicYearController;
  late TextEditingController _systemController;
  late TextEditingController _levelController;
  late TextEditingController _universityNameController;
  late TextEditingController _temporaryAddressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _reasonController;

  String _genderValue = 'male';

  @override
  void initState() {
    super.initState();
    final student = Globals().thongTinSinhVienModel.value;
    final classInfo = Globals().lopDaoTaoModel.value;
    final cohortInfo = Globals().nienKhoaDaoTaoModel.value;
    final cubit = context.read<DormitoryRegistrationCubit>();

    _studentCodeController = TextEditingController(text: student?.maSinhVien ?? '');
    _fullNameController = TextEditingController(text: student?.hoVaTen ?? '');

    String dobStr = '';
    if (student?.ngaySinh != null) {
      dobStr = DateFormat('yyyy-MM-dd').format(student!.ngaySinh!);
    }
    _dobController = TextEditingController(text: dobStr);

    _genderValue = student?.gioiTinh?.toLowerCase() == 'nữ' ? 'female' : 'male';
    _genderController = TextEditingController(text: _genderValue);

    _cccdController = TextEditingController(text: cubit.tempCccd ?? student?.soCmtCccd ?? '');

    String issueDateStr = '';
    if (student?.ngayCapCmtCccd != null) {
      issueDateStr = DateFormat('yyyy-MM-dd').format(student!.ngayCapCmtCccd!);
    }
    _cccdIssueDateController = TextEditingController(text: cubit.tempCccdIssueDate ?? issueDateStr);

    _hometownController = TextEditingController(
      text: cubit.tempHometown ?? student?.hoKhauThuongTruDuongThon ?? student?.hoKhauThuongTruPhuongXa ?? '',
    );

    _classNameController = TextEditingController(text: classInfo?.ten ?? '');
    _majorController = TextEditingController(text: classInfo?.ten ?? '');
    _academicYearController = TextEditingController(text: cohortInfo?.ten ?? '');
    _systemController = TextEditingController(text: student != null ? 'Chính quy' : '');
    _levelController = TextEditingController(text: student != null ? 'Đại học' : '');
    _universityNameController = TextEditingController(text: student != null ? 'Đại học Quốc gia Hà Nội' : '');

    _temporaryAddressController = TextEditingController(
      text: cubit.tempTemporaryAddress ?? student?.noiOHienNayDuongThon ?? student?.noiOHienNayPhuongXa ?? '',
    );

    _phoneController = TextEditingController(text: cubit.tempPhone ?? student?.mobile ?? student?.tel ?? '');
    _emailController = TextEditingController(text: cubit.tempEmail ?? student?.email ?? '');
    _reasonController = TextEditingController(text: cubit.tempReason ?? '');
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _cccdController.dispose();
    _cccdIssueDateController.dispose();
    _hometownController.dispose();
    _classNameController.dispose();
    _majorController.dispose();
    _academicYearController.dispose();
    _systemController.dispose();
    _levelController.dispose();
    _universityNameController.dispose();
    _temporaryAddressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void saveDataToCubit() {
    final cubit = context.read<DormitoryRegistrationCubit>();
    cubit.tempPhone = _phoneController.text.trim();
    cubit.tempEmail = _emailController.text.trim();
    cubit.tempCccd = _cccdController.text.trim();
    cubit.tempCccdIssueDate = _cccdIssueDateController.text.trim();
    cubit.tempHometown = _hometownController.text.trim();
    cubit.tempTemporaryAddress = _temporaryAddressController.text.trim();
    cubit.tempReason = _reasonController.text.trim();
  }

  Future<void> _selectDate(
      BuildContext context,
      TextEditingController controller,
      ) async {
    DateTime selectedDate = DateTime.tryParse(controller.text) ?? DateTime.now();

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E6EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF078B3E),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Chọn ngày',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: AppFontSizes.medium,
                            color: Color(0xFF111318),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppTheme.colorMain,
                          secondary: AppTheme.colorMain,
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: selectedDate,
                        firstDate: DateTime(1970),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        onDateChanged: (date) {
                          setModalState(() {
                            selectedDate = date;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Hủy'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF666B75),
                              side: const BorderSide(
                                color: Color(0xFFE3E6EB),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context, selectedDate);
                            },
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Chọn ngày'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF078B3E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
  Future<void> _pickImageLocal(String uploadSlot) async {
    final cubit = context.read<DormitoryRegistrationCubit>();
    final XFile? image = await _picker.pickImage(
      maxHeight: 2000,
      maxWidth: 2000,
      source: ImageSource.gallery,
    );
    if (image != null) {
      final file = File(image.path);
      setState(() {
        if (uploadSlot == 'cccd_front') {
          cubit.selectCCCDFront(file);
        } else if (uploadSlot == 'cccd_back') {
          cubit.selectCCCDBack(file);
        } else {
          cubit.addProofFile(file);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DormitoryRegistrationCubit>();

    return BlocListener<DormitoryRegistrationCubit, DormitoryRegistrationState>(
      listener: (context, state) {
        if (state is DormitoryRegistrationUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải file lên thành công')),
          );
        }
        if (state is DormitoryRegistrationUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thông tin sinh viên
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE3E6EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_outline, color: Color(0xFF078B3E), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin sinh viên',
                            style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField('Mã sinh viên', _studentCodeController, readOnly: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField('Họ và tên', _fullNameController, readOnly: true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Ngày sinh',
                              _dobController,
                              readOnly: true,
                              icon: Icons.calendar_today_outlined,
                              onTap: () => _selectDate(context, _dobController),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdownField('Giới tính', _genderValue, (val) {
                              if (val != null) {
                                setState(() {
                                  _genderValue = val;
                                  _genderController.text = val;
                                });
                              }
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 2. Giấy tờ tùy thân
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE3E6EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: Color(0xFF078B3E), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Giấy tờ tùy thân',
                            style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Số CCCD *',
                              _cccdController,
                              validator: (v) => v == null || v.isEmpty ? 'Nhập số CCCD' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              'Ngày cấp CCCD *',
                              _cccdIssueDateController,
                              readOnly: true,
                              icon: Icons.calendar_today_outlined,
                              onTap: () => _selectDate(context, _cccdIssueDateController),
                              validator: (v) => v == null || v.isEmpty ? 'Chọn ngày cấp' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        'Quê quán *',
                        _hometownController,
                        validator: (v) => v == null || v.isEmpty ? 'Nhập quê quán' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 3. Thông tin học tập
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE3E6EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school_outlined, color: Color(0xFF078B3E), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin học tập',
                            style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField('Lớp', _classNameController, readOnly: true)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildField('Ngành', _majorController, readOnly: true)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildField('Năm học', _academicYearController, readOnly: true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildField('Hệ đào tạo', _systemController, readOnly: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField('Bậc đào tạo', _levelController, readOnly: true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField('Trường', _universityNameController, readOnly: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 4. Liên hệ & ưu tiên
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE3E6EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_outlined, color: Color(0xFF078B3E), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Liên hệ & ưu tiên',
                            style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'Địa chỉ tạm trú *',
                        _temporaryAddressController,
                        validator: (v) => v == null || v.isEmpty ? 'Nhập địa chỉ tạm trú' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Số điện thoại *',
                              _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty ? 'Nhập số điện thoại' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              'Email *',
                              _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.isEmpty ? 'Nhập email' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        'Đối tượng ưu tiên',
                        TextEditingController(text: cubit.selectedPriorityObject?.name ?? 'Không'),
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 5. Minh chứng & lý do
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE3E6EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.attach_file, color: Color(0xFF078B3E), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Minh chứng & lý do',
                            style: TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                       // CCCD mặt trước
                      _buildUploadRow(
                        'CCCD mặt trước *',
                        cubit.cccdFrontFile != null
                            ? p.basename(cubit.cccdFrontFile!.path)
                            : (cubit.cccdFrontAttachment?.name ?? 'Chưa tải ảnh lên'),
                        () => _pickImageLocal('cccd_front'),
                      ),
                      const Divider(height: 12, color: Color(0xFFE3E6EB)),
                      // CCCD mặt sau
                      _buildUploadRow(
                        'CCCD mặt sau *',
                        cubit.cccdBackFile != null
                            ? p.basename(cubit.cccdBackFile!.path)
                            : (cubit.cccdBackAttachment?.name ?? 'Chưa tải ảnh lên'),
                        () => _pickImageLocal('cccd_back'),
                      ),
                      const Divider(height: 12, color: Color(0xFFE3E6EB)),
                      // Giấy tờ ưu tiên
                      _buildUploadRow(
                        'Giấy tờ ưu tiên (nếu có)',
                        (cubit.proofFiles.length + cubit.proofAttachments.length) == 0
                            ? 'Chưa chọn tệp'
                            : '${cubit.proofFiles.length + cubit.proofAttachments.length} tệp đã chọn',
                        () => _pickImageLocal('proof'),
                      ),
                      const SizedBox(height: 16),
                      // Lý do đăng ký
                      const Text(
                        'Lý do đăng ký nội trú',
                        style: TextStyle(color: Color(0xFF666B75), fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE3E6EB)),
                        ),
                        child: Stack(
                          children: [
                            TextField(
                              controller: _reasonController,
                              maxLines: 4,
                              maxLength: 500,
                              onChanged: (text) {
                                setState(() {});
                              },
                              style: const TextStyle(fontSize: AppFontSizes.mediumSmall, color: Color(0xFF111318)),
                              decoration: const InputDecoration(
                                hintText: 'Nhập lý do...',
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Text(
                                '${_reasonController.text.length}/500',
                                style: const TextStyle(color: Colors.grey, fontSize: AppFontSizes.font11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (cubit.proofFiles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cubit.proofFiles.map(_buildLocalImagePreview).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    IconData? icon,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF8F9FB) : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE3E6EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF666B75), fontSize: AppFontSizes.font11),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  onTap: onTap,
                  keyboardType: keyboardType,
                  validator: validator,
                  style: const TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111318),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (icon != null)
                GestureDetector(
                  onTap: onTap,
                  child: Icon(icon, size: 16, color: const Color(0xFF666B75)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, Function(String?) onChanged) {
    return NtCustomDropdown<String>(
      label: label,
      hintText: 'Chọn giới tính',
      value: value,
      items: const ['male', 'female'],
      itemAsString: (item) => item == 'male' ? 'Nam' : 'Nữ',
      onChanged: onChanged,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InteractiveViewer(
            child: Image.file(file, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
  Widget _buildUploadRow(String title, String fileName, VoidCallback onUpload) {
    return Row(
      children: [
        const Icon(Icons.description_outlined, color: Color(0xFF078B3E), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
              ),
              Text(
                fileName,
                style: const TextStyle(fontSize: AppFontSizes.extraSmall, color: Color(0xFF666B75)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFAFFFC),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
              side: const BorderSide(color: Color(0xFFCDEBD7)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: const Text(
            'Tải lên',
            style: TextStyle(color: Color(0xFF078B3E), fontSize: AppFontSizes.font11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
