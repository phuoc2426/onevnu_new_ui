import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:path/path.dart' as p;
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_noi_tru/widgets/nt_custom_dropdown.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DRStep3InfoScreen extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const DRStep3InfoScreen({super.key, required this.formKey});

  @override
  State<DRStep3InfoScreen> createState() => DRStep3InfoScreenState();
}

class DRStep3InfoScreenState extends State<DRStep3InfoScreen> {
  final _picker = ImagePicker();
  bool _isImagePickerActive = false;
  static const int _maxUploadMb = 5;
  static const int _maxUploadBytes = _maxUploadMb * 1024 * 1024;

  static const int _defaultMaxImageSide = 1600;
  static const int _fallbackMaxImageSide = 1280;

  static const int _defaultImageQuality = 82;
  static const int _minImageQuality = 55;

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
  bool _isApplicant = false;
  final List<_FamilyMemberForm> _familyForms = <_FamilyMemberForm>[];

  @override
  void initState() {
    super.initState();
    final student = Globals().thongTinSinhVienModel.value;
    final classInfo = Globals().lopDaoTaoModel.value;
    final cohortInfo = Globals().nienKhoaDaoTaoModel.value;
    final cubit = context.read<DormitoryRegistrationCubit>();

    _familyForms.addAll(
      cubit.familyMembers.map(_FamilyMemberForm.fromPayload),
    );

    _studentCodeController =
        TextEditingController(text: student?.maSinhVien ?? '');
    _fullNameController = TextEditingController(text: student?.hoVaTen ?? '');

    String dobStr = '';
    if (student?.ngaySinh != null) {
      dobStr = DateFormat('yyyy-MM-dd').format(student!.ngaySinh!);
    }
    _dobController = TextEditingController(text: dobStr);
    _isApplicant = student == null;

    _genderValue = student?.gioiTinh?.toLowerCase() == 'nữ' ? 'female' : 'male';
    _genderController = TextEditingController(text: _genderValue);

    _cccdController =
        TextEditingController(text: cubit.tempCccd ?? student?.soCmtCccd ?? '');

    String issueDateStr = '';
    if (student?.ngayCapCmtCccd != null) {
      issueDateStr = DateFormat('yyyy-MM-dd').format(student!.ngayCapCmtCccd!);
    }
    _cccdIssueDateController =
        TextEditingController(text: cubit.tempCccdIssueDate ?? issueDateStr);

    _hometownController = TextEditingController(
      text: cubit.tempHometown ?? student?.hoKhauThuongTruDuongThon ??
          student?.hoKhauThuongTruPhuongXa ?? '',
    );

    _classNameController = TextEditingController(text: classInfo?.ten ?? '');
    _majorController = TextEditingController(text: classInfo?.ten ?? '');
    _academicYearController =
        TextEditingController(text: cohortInfo?.ten ?? '');
    _systemController =
        TextEditingController(text: student != null ? 'Chính quy' : '');
    _levelController =
        TextEditingController(text: student != null ? 'Đại học' : '');
    _universityNameController = TextEditingController(
        text: student != null ? 'Đại học Quốc gia Hà Nội' : '');

    _temporaryAddressController = TextEditingController(
      text: cubit.tempTemporaryAddress ?? student?.noiOHienNayDuongThon ??
          student?.noiOHienNayPhuongXa ?? '',
    );

    _phoneController = TextEditingController(
        text: cubit.tempPhone ?? student?.mobile ?? student?.tel ?? '');
    _emailController =
        TextEditingController(text: cubit.tempEmail ?? student?.email ?? '');
    _reasonController = TextEditingController(text: cubit.tempReason ?? '');

    _loadApplicantCacheIfAvailable();
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
    for (final _FamilyMemberForm form in _familyForms) {
      form.dispose();
    }
    super.dispose();
  }

  Future<double> _fileSizeMb(File file) async {
    final bytes = await file.length();
    return bytes / 1024 / 1024;
  }

  Future<void> _validateImageSize(File file) async {
    final sizeMb = await _fileSizeMb(file);

    if (sizeMb > _maxUploadMb) {
      throw Exception(
        'Ảnh ${p.basename(file.path)} có dung lượng ${sizeMb.toStringAsFixed(
            2)}MB, '
            'vượt quá giới hạn $_maxUploadMb MB. Vui lòng chọn ảnh rõ hơn nhưng dung lượng nhỏ hơn.',
      );
    }
  }

  Future<File> _compressImageToUploadStandard(File originalFile) async {
    if (!await originalFile.exists()) {
      throw Exception(
        'Không tìm thấy ảnh ${p.basename(originalFile.path)} trên thiết bị.',
      );
    }

    final Directory tempDir = await getTemporaryDirectory();
    final int originalSize = await originalFile.length();

    int quality = _defaultImageQuality;
    int maxSide = _defaultMaxImageSide;
    File? lastCompressedFile;

    // Luôn chuẩn hóa mọi ảnh sang JPEG trước khi upload, kể cả ảnh gốc
    // đã nhỏ hơn 5 MB. Điều này tránh gửi trực tiếp HEIC/PNG/WEBP lên API.
    while (quality >= _minImageQuality) {
      final String targetPath = p.join(
        tempDir.path,
        'noi_tru_${DateTime.now().microsecondsSinceEpoch}'
            '_q${quality}_${maxSide}px.jpg',
      );

      final XFile? compressed =
      await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxSide,
        minHeight: maxSide,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed == null) {
        throw Exception(
          'Không thể xử lý ảnh ${p.basename(originalFile.path)}. '
              'Vui lòng chọn ảnh JPG hoặc PNG khác.',
        );
      }

      lastCompressedFile = File(compressed.path);
      final int compressedSize = await lastCompressedFile.length();

      debugPrint(
        '[DORMITORY-IMAGE-COMPRESS] '
            'source=${p.basename(originalFile.path)}, '
            'sourceBytes=$originalSize, '
            'output=${p.basename(lastCompressedFile.path)}, '
            'outputBytes=$compressedSize, '
            'quality=$quality, '
            'maxSide=$maxSide',
      );

      if (compressedSize <= _maxUploadBytes) {
        return lastCompressedFile;
      }

      quality -= 8;

      if (quality <= 66) {
        maxSide = _fallbackMaxImageSide;
      }
    }

    if (lastCompressedFile == null) {
      throw Exception(
        'Không thể tạo ảnh tải lên từ ${p.basename(originalFile.path)}.',
      );
    }

    await _validateImageSize(lastCompressedFile);
    return lastCompressedFile;
  }

  Future<void> _loadApplicantCacheIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final applicantCccd = prefs.getString('applicant_cccd');
    if (applicantCccd == null || applicantCccd.isEmpty) return;

    final cubit = context.read<DormitoryRegistrationCubit>();

    // 1. Ưu tiên giá trị từ Cubit (nếu có) → SharedPreferences → rỗng
    final emailFromCache = prefs.getString('applicant_email') ?? '';

    if (cubit.tempEmail != null && cubit.tempEmail!.isNotEmpty) {
      _emailController.text = cubit.tempEmail!;
    } else if (emailFromCache.isNotEmpty) {
      _emailController.text = emailFromCache;
      cubit.tempEmail = emailFromCache;   // đồng bộ ngược vào Cubit
    } else {
      _emailController.text = '';         // hoặc giữ nguyên giá trị cũ của controller
    }

    // Tương tự cho họ tên, CCCD, ngày sinh...
    final fullNameFromCache = prefs.getString('applicant_fullname') ?? '';
    if (cubit.tempFullName != null && cubit.tempFullName!.isNotEmpty) {
      _fullNameController.text = cubit.tempFullName!;
    } else if (fullNameFromCache.isNotEmpty) {
      _fullNameController.text = fullNameFromCache;
      cubit.tempFullName = fullNameFromCache;
    } else {
      _fullNameController.text = '';
    }

    // CCCD
    if (cubit.tempCccd != null && cubit.tempCccd!.isNotEmpty) {
      _cccdController.text = cubit.tempCccd!;
    } else {
      _cccdController.text = applicantCccd;  // applicant_cccd luôn có
      cubit.tempCccd = applicantCccd;
    }

    // DOB
    final dobFromCache = prefs.getString('applicant_dob') ?? '';
    if (cubit.tempDOB != null && cubit.tempDOB!.isNotEmpty) {
      _dobController.text = cubit.tempDOB!;
    } else if (dobFromCache.isNotEmpty) {
      _dobController.text = dobFromCache;
      cubit.tempDOB = dobFromCache;
    } else {
      _dobController.text = '';
    }

    // Sau khi đồng bộ, không cần gọi setState vì controller.text đã thay đổi,
    // nhưng nếu có UI phụ thuộc thì nên gọi setState.
    if (mounted) setState(() {});
  }

  void saveDataToCubit() {
    final DormitoryRegistrationCubit cubit =
        context.read<DormitoryRegistrationCubit>();

    cubit.tempFullName = _fullNameController.text.trim();
    cubit.tempPhone = _phoneController.text.trim();
    cubit.tempEmail = _emailController.text.trim();
    cubit.tempDOB = _dobController.text.trim();
    cubit.tempGender = _genderValue;
    cubit.tempCccd = _cccdController.text.trim();
    cubit.tempCccdIssueDate = _cccdIssueDateController.text.trim();
    cubit.tempHometown = _hometownController.text.trim();
    cubit.tempTemporaryAddress = _temporaryAddressController.text.trim();
    cubit.tempReason = _reasonController.text.trim();
    cubit.replaceFamilyMembers(
      _familyForms
          .map((_FamilyMemberForm item) => item.toPayload())
          .where((FamilyMemberPayload item) => item.fullName.isNotEmpty)
          .toList(),
    );
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller,) async {
    DateTime selectedDate = DateTime.tryParse(controller.text) ??
        DateTime.now();

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
                        colorScheme: Theme
                            .of(context)
                            .colorScheme
                            .copyWith(
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
      if (controller == _dobController) {
        _saveApplicantCache();  // cập nhật cache ngay
      }
    }
  }
  Future<void> _saveApplicantCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('applicant_cccd', _cccdController.text.trim());
    await prefs.setString('applicant_fullname', _fullNameController.text.trim());
    await prefs.setString('applicant_email', _emailController.text.trim());
    await prefs.setString('applicant_dob', _dobController.text.trim());
    await prefs.setString('applicant_phone', _phoneController.text.trim()); // thêm
  }
  Future<void> _pickImageLocal(String uploadSlot) async {
    final DormitoryRegistrationCubit cubit =
        context.read<DormitoryRegistrationCubit>();

    if (_isImagePickerActive) {
      debugPrint(
        '[DORMITORY-IMAGE-PICKER] ignored duplicate request: slot=$uploadSlot',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
              content: Text(
                'Trình chọn ảnh đang mở. Vui lòng chọn hoặc đóng cửa sổ hiện tại trước.',
              ),
            ),
          );
      }
      return;
    }

    _isImagePickerActive = true;

    try {
      final XFile? image = await _picker.pickImage(
        maxHeight: _defaultMaxImageSide.toDouble(),
        maxWidth: _defaultMaxImageSide.toDouble(),
        imageQuality: _defaultImageQuality,
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final File originalFile = File(image.path);
      final double originalSizeMb = await _fileSizeMb(originalFile);

      final File file = await _compressImageToUploadStandard(originalFile);

      await _validateImageSize(file);

      final double finalSizeMb = await _fileSizeMb(file);

      debugPrint(
        '[DORMITORY-IMAGE-READY] '
        'slot=$uploadSlot, '
        'source=${p.basename(originalFile.path)}, '
        'sourceSize=${originalSizeMb.toStringAsFixed(2)}MB, '
        'output=${p.basename(file.path)}, '
        'extension=${p.extension(file.path).toLowerCase()}, '
        'outputSize=${finalSizeMb.toStringAsFixed(2)}MB, '
        'path=${file.path}',
      );

      if (!mounted) return;

      if (uploadSlot == 'avatar') {
        cubit.selectAvatar(file);
      } else if (uploadSlot == 'cccd_front') {
        cubit.selectCCCDFront(file);
      } else if (uploadSlot == 'cccd_back') {
        cubit.selectCCCDBack(file);
      } else {
        cubit.addProofFile(file);
      }
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[DORMITORY-IMAGE-PICKER-ERROR] '
        'slot=$uploadSlot, code=${error.code}, message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final String message = error.code == 'already_active'
          ? 'Trình chọn ảnh đã được mở. Vui lòng đóng cửa sổ chọn ảnh cũ rồi thử lại.'
          : 'Không thể mở thư viện ảnh. Vui lòng thử lại.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.red,
            content: Text(message),
          ),
        );
    } catch (error, stackTrace) {
      debugPrint(
        '[DORMITORY-IMAGE-PICKER-ERROR] slot=$uploadSlot, error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.red,
            content: Text(
              AppErrorMapper.map(
                error,
                fallbackMessage:
                    'Không thể xử lý ảnh đã chọn. Vui lòng thử lại.',
              ).userMessage,
            ),
          ),
        );
    } finally {
      _isImagePickerActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DormitoryRegistrationCubit>();

    return Theme(
      data: _buildGreenFormTheme(context),
      child: BlocListener<DormitoryRegistrationCubit, DormitoryRegistrationState>(
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
              _buildAvatarCard(cubit),
              const SizedBox(height: 12),
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
                          Icon(Icons.person_outline, color: Color(0xFF078B3E),
                              size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin sinh viên',
                            style: TextStyle(fontSize: AppFontSizes.font11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField(
                              'Mã sinh viên', _studentCodeController,
                              readOnly: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField(
                              'Họ và tên', _fullNameController,
                              readOnly: true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Ngày sinh *',
                              _dobController,
                              readOnly: false,
                              icon: Icons.calendar_today_outlined,
                              onTap: _isApplicant ? () => _selectDate(context, _dobController) : null,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng chọn ngày sinh'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdownField(
                                'Giới tính', _genderValue, (val) {
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
                          Icon(Icons.badge_outlined, color: Color(0xFF078B3E),
                              size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Giấy tờ tùy thân',
                            style: TextStyle(fontSize: AppFontSizes.font11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111318)),
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
                              validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Nhập số CCCD'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              'Ngày cấp CCCD *',
                              _cccdIssueDateController,
                              readOnly: true,
                              icon: Icons.calendar_today_outlined,
                              onTap: () => _selectDate(
                                  context, _cccdIssueDateController),
                              validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Chọn ngày cấp'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        'Quê quán *',
                        _hometownController,
                        validator: (v) =>
                        v == null || v.isEmpty
                            ? 'Nhập quê quán'
                            : null,
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
                          Icon(Icons.school_outlined, color: Color(0xFF078B3E),
                              size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin học tập',
                            style: TextStyle(fontSize: AppFontSizes.font11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField(
                              'Lớp', _classNameController, readOnly: true)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildField(
                              'Ngành', _majorController, readOnly: true)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildField(
                              'Năm học', _academicYearController,
                              readOnly: true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildField(
                              'Hệ đào tạo', _systemController, readOnly: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField(
                              'Bậc đào tạo', _levelController, readOnly: true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                          'Trường', _universityNameController, readOnly: true),
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
                          Icon(Icons.phone_outlined, color: Color(0xFF078B3E),
                              size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Liên hệ & ưu tiên',
                            style: TextStyle(fontSize: AppFontSizes.font11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'Địa chỉ tạm trú *',
                        _temporaryAddressController,
                        validator: (v) =>
                        v == null || v.isEmpty
                            ? 'Nhập địa chỉ tạm trú'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Số điện thoại *',
                              _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Nhập số điện thoại'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              'Email *',
                              _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Nhập email'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        'Đối tượng ưu tiên',
                        TextEditingController(
                          text: cubit.selectedPriorityObjectNames.isEmpty
                              ? 'Không'
                              : cubit.selectedPriorityObjectNames,
                        ),
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildFamilyInformationCard(),
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
                          Icon(Icons.attach_file, color: Color(0xFF078B3E),
                              size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Minh chứng & lý do',
                            style: TextStyle(fontSize: AppFontSizes.font11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111318)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // CCCD mặt trước
                      // CCCD mặt trước
                      _buildSingleImageUploadRow(
                        title: 'CCCD mặt trước *',
                        file: cubit.cccdFrontFile,
                        uploadedName: cubit.cccdFrontAttachment?.name,
                        onSelect: () => _pickImageLocal('cccd_front'),
                        onPreview: cubit.cccdFrontFile != null
                            ? () => _showImagePreview(cubit.cccdFrontFile!)
                            : null,
                        onRemove: () {
                          setState(() {
                            cubit.removeCCCDFront();
                          });
                        },
                      ),
                      const Divider(height: 12, color: Color(0xFFE3E6EB)),

// CCCD mặt sau
                      _buildSingleImageUploadRow(
                        title: 'CCCD mặt sau *',
                        file: cubit.cccdBackFile,
                        uploadedName: cubit.cccdBackAttachment?.name,
                        onSelect: () => _pickImageLocal('cccd_back'),
                        onPreview: cubit.cccdBackFile != null
                            ? () => _showImagePreview(cubit.cccdBackFile!)
                            : null,
                        onRemove: () {
                          setState(() {
                            cubit.removeCCCDBack();
                          });
                        },
                      ),
                      const Divider(height: 12, color: Color(0xFFE3E6EB)),

                      // Giấy tờ ưu tiên
                      _buildMultiImageUploadRow(
                        title: 'Giấy tờ ưu tiên (nếu có)',
                        files: cubit.proofFiles,
                        uploadedCount: cubit.proofAttachments.length,
                        onSelect: () => _pickImageLocal('proof'),
                        onView: () => _showProofImagesSheet(cubit),
                      ),
                      const SizedBox(height: 16),
                      // Lý do đăng ký
                      const Text(
                        'Lý do đăng ký nội trú',
                        style: TextStyle(color: Color(0xFF666B75),
                            fontSize: AppFontSizes.font11,
                            fontWeight: FontWeight.bold),
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
                              cursorColor: const Color(0xFF078B3E),
                              onChanged: (text) {
                                setState(() {});
                              },
                              style: const TextStyle(
                                fontSize: AppFontSizes.mediumSmall,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111318),
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Nhập lý do...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: AppFontSizes.mediumSmall,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Text(
                                '${_reasonController.text.length}/500',
                                style: const TextStyle(color: Colors.grey,
                                    fontSize: AppFontSizes.font11),
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

            ],
          ),
        ),
      ),
      ),
    );
  }

  ThemeData _buildGreenFormTheme(BuildContext context) {
    final ThemeData base = Theme.of(context);
    const Color green = Color(0xFF078B3E);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: green,
        secondary: green,
        surface: Colors.white,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: green,
        selectionColor: Color(0x33078B3E),
        selectionHandleColor: green,
      ),
      splashColor: const Color(0x14078B3E),
      highlightColor: const Color(0x0F078B3E),
    );
  }

  InputDecoration _formDecoration({
    required String label,
    bool readOnly = false,
    IconData? suffixIcon,
  }) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE3DF)),
    );

    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: readOnly ? const Color(0xFFF4F6F5) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: AppFontSizes.font11,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF078B3E),
        fontSize: AppFontSizes.font11,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: AppFontSizes.mediumSmall,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFDC2626),
        fontSize: AppFontSizes.extraSmall,
      ),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 18, color: const Color(0xFF078B3E)),
      border: border,
      enabledBorder: border,
      disabledBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
      ),
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF078B3E), width: 1.6),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  Widget _buildAvatarCard(DormitoryRegistrationCubit cubit) {
    final File? avatar = cubit.avatarFile;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE3E6EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: avatar == null ? null : () => _showImagePreview(avatar),
              child: Container(
                width: 86,
                height: 108,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCDEBD7)),
                ),
                child: avatar == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.badge_outlined,
                            size: 34,
                            color: Color(0xFF078B3E),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Ảnh 3x4',
                            style: TextStyle(
                              fontSize: AppFontSizes.extraSmall,
                              color: Color(0xFF666B75),
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(avatar, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Ảnh thẻ sinh viên *',
                    style: TextStyle(
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Ảnh chân dung rõ mặt, nền sáng. Ảnh được chuyển sang JPG, nén dưới 5 MB và tải lên hồ sơ sinh viên.',
                    style: TextStyle(
                      fontSize: AppFontSizes.extraSmall,
                      color: Color(0xFF666B75),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _pickImageLocal('avatar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF078B3E),
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          avatar == null
                              ? Icons.add_a_photo_outlined
                              : Icons.refresh_rounded,
                          size: 18,
                        ),
                        label: Text(avatar == null ? 'Chọn ảnh' : 'Chọn lại'),
                      ),
                      if (avatar != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            cubit.removeAvatar();
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Xóa'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyInformationCard() {
    return Card(
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
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.family_restroom_rounded,
                  color: Color(0xFF078B3E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Thông tin gia đình',
                    style: TextStyle(
                      fontSize: AppFontSizes.font11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addFamilyMember,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm người thân'),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Có thể khai báo bố, mẹ hoặc người giám hộ. Các trường nghề nghiệp và số điện thoại không bắt buộc.',
              style: TextStyle(
                fontSize: AppFontSizes.extraSmall,
                color: Color(0xFF666B75),
                height: 1.35,
              ),
            ),
            if (_familyForms.isEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Chưa khai báo người thân.',
                  style: TextStyle(
                    fontSize: AppFontSizes.font11,
                    color: Color(0xFF666B75),
                  ),
                ),
              ),
            ] else
              ..._familyForms.asMap().entries.map(
                (MapEntry<int, _FamilyMemberForm> entry) =>
                    _buildFamilyMemberEditor(entry.key, entry.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberEditor(
    int index,
    _FamilyMemberForm form,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E6EB)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NtCustomDropdown<String>(
                  label: 'Quan hệ *',
                  hintText: 'Chọn quan hệ',
                  value: form.relationship,
                  items: const <String>['father', 'mother', 'guardian'],
                  itemAsString: (String value) {
                    switch (value) {
                      case 'father':
                        return 'Bố';
                      case 'mother':
                        return 'Mẹ';
                      case 'guardian':
                        return 'Người giám hộ';
                      default:
                        return value;
                    }
                  },
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => form.relationship = value);
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: 'Xóa người thân',
                onPressed: () => _removeFamilyMember(index),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildField(
            'Họ và tên *',
            form.fullNameController,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nhập họ tên người thân';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildField(
                  'Năm sinh',
                  form.birthYearController,
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final int? year = int.tryParse(text);
                    final int currentYear = DateTime.now().year;
                    if (year == null || year < 1900 || year > currentYear) {
                      return 'Năm sinh không hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildField(
                  'Số điện thoại',
                  form.phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    if (text.length > 20) return 'Tối đa 20 ký tự';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildField('Nghề nghiệp', form.occupationController),
        ],
      ),
    );
  }

  void _addFamilyMember() {
    setState(() {
      _familyForms.add(_FamilyMemberForm.empty());
    });
  }

  void _removeFamilyMember(int index) {
    final _FamilyMemberForm removed = _familyForms.removeAt(index);
    removed.dispose();
    setState(() {});
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
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: const Color(0xFF078B3E),
      style: TextStyle(
        fontSize: AppFontSizes.mediumSmall,
        fontWeight: FontWeight.w600,
        color: readOnly
            ? const Color(0xFF4B5563)
            : const Color(0xFF111318),
        height: 1.3,
      ),
      decoration: _formDecoration(
        label: label,
        readOnly: readOnly,
        suffixIcon: icon,
      ),
    );
  }

  Widget _buildDropdownField(String label, String value,
      Function(String?) onChanged) {
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

  Future<void> _showImagePreview(File file) async {
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
              children: <Widget>[
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

  Widget _buildSingleImageUploadRow({
    required String title,
    required File? file,
    required String? uploadedName,
    required VoidCallback onSelect,
    required VoidCallback? onPreview,
    required VoidCallback onRemove,
  }) {
    final hasLocalFile = file != null;
    final hasUploadedFile = uploadedName != null && uploadedName
        .trim()
        .isNotEmpty;

    final displayName = hasLocalFile
        ? p.basename(file.path)
        : hasUploadedFile
        ? uploadedName
        : 'Chưa tải ảnh lên';

    return Row(
      children: [
        const Icon(
          Icons.image_outlined,
          color: Color(0xFF078B3E),
          size: 20,
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSizes.font11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111318),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: AppFontSizes.extraSmall,
                  color: Color(0xFF666B75),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        if (hasLocalFile) ...[
          OutlinedButton(
            onPressed: onPreview,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF078B3E),
              side: const BorderSide(color: Color(0xFFCDEBD7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              'Preview',
              style: TextStyle(
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFAFFFC),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: const BorderSide(color: Color(0xFFCDEBD7)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              'Chọn lại',
              style: TextStyle(
                color: Color(0xFF078B3E),
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Xóa ảnh',
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.red,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ] else
          ElevatedButton(
            onPressed: onSelect,
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
              style: TextStyle(
                color: Color(0xFF078B3E),
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMultiImageUploadRow({
    required String title,
    required List<File> files,
    required int uploadedCount,
    required VoidCallback onSelect,
    required VoidCallback onView,
  }) {
    final total = files.length + uploadedCount;
    final hasFiles = total > 0;

    return Row(
      children: [
        const Icon(
          Icons.collections_outlined,
          color: Color(0xFF078B3E),
          size: 20,
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSizes.font11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111318),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasFiles ? '$total ảnh đã chọn' : 'Chưa chọn ảnh',
                style: const TextStyle(
                  fontSize: AppFontSizes.extraSmall,
                  color: Color(0xFF666B75),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        if (hasFiles) ...[
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF078B3E),
              side: const BorderSide(color: Color(0xFFCDEBD7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              'Xem ảnh',
              style: TextStyle(
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],

        ElevatedButton(
          onPressed: onSelect,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFAFFFC),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
              side: const BorderSide(color: Color(0xFFCDEBD7)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Text(
            hasFiles ? 'Thêm ảnh' : 'Tải lên',
            style: const TextStyle(
              color: Color(0xFF078B3E),
              fontSize: AppFontSizes.font11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showProofImagesSheet(DormitoryRegistrationCubit cubit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final localFiles = cubit.proofFiles;
            final uploadedFiles = cubit.proofAttachments;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E6EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Icon(
                          Icons.collections_outlined,
                          color: Color(0xFF078B3E),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Ảnh giấy tờ ưu tiên',
                            style: TextStyle(
                              fontSize: AppFontSizes.medium,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111318),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (localFiles.isEmpty && uploadedFiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Chưa có ảnh nào được chọn',
                            style: TextStyle(color: Color(0xFF666B75)),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.55,
                        child: GridView.builder(
                          itemCount: localFiles.length + uploadedFiles.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final isLocal = index < localFiles.length;

                            if (isLocal) {
                              final file = localFiles[index];

                              return _buildLocalProofGridItem(
                                file: file,
                                onTap: () => _showImagePreview(file),
                                onRemove: () {
                                  setModalState(() {
                                    cubit.removeProofFileAt(index);
                                  });
                                  setState(() {});
                                },
                              );
                            }

                            final uploadedIndex = index - localFiles.length;
                            final uploaded = uploadedFiles[uploadedIndex];

                            return _buildUploadedProofGridItem(
                              name: uploaded.name ?? 'Ảnh đã tải lên',
                              onRemove: () {
                                setModalState(() {
                                  cubit.removeProofAttachmentAt(uploadedIndex);
                                });
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUploadedProofGridItem({
    required String name,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE3E6EB),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF078B3E),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF666B75),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalProofGridItem({
    required File file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                file,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _FamilyMemberForm {
  String relationship;
  final TextEditingController fullNameController;
  final TextEditingController birthYearController;
  final TextEditingController occupationController;
  final TextEditingController phoneController;

  _FamilyMemberForm({
    required this.relationship,
    required this.fullNameController,
    required this.birthYearController,
    required this.occupationController,
    required this.phoneController,
  });

  factory _FamilyMemberForm.empty() {
    return _FamilyMemberForm(
      relationship: 'father',
      fullNameController: TextEditingController(),
      birthYearController: TextEditingController(),
      occupationController: TextEditingController(),
      phoneController: TextEditingController(),
    );
  }

  factory _FamilyMemberForm.fromPayload(FamilyMemberPayload payload) {
    return _FamilyMemberForm(
      relationship: payload.relationship,
      fullNameController: TextEditingController(text: payload.fullName),
      birthYearController: TextEditingController(
        text: payload.birthYear?.toString() ?? '',
      ),
      occupationController: TextEditingController(
        text: payload.occupation ?? '',
      ),
      phoneController: TextEditingController(
        text: payload.phoneNumber ?? '',
      ),
    );
  }

  FamilyMemberPayload toPayload() {
    return FamilyMemberPayload(
      relationship: relationship,
      fullName: fullNameController.text.trim(),
      birthYear: int.tryParse(birthYearController.text.trim()),
      occupation: occupationController.text.trim().isEmpty
          ? null
          : occupationController.text.trim(),
      phoneNumber: phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
    );
  }

  void dispose() {
    fullNameController.dispose();
    birthYearController.dispose();
    occupationController.dispose();
    phoneController.dispose();
  }
}

