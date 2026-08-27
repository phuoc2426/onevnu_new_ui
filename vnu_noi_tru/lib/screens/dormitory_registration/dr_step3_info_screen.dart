import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:vnu_noi_tru/domain/registration/dormitory_date_codec.dart';
import 'package:vnu_noi_tru/domain/registration/dormitory_student_draft.dart';
import 'package:vnu_noi_tru/services/registration/dormitory_local_file_store.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:path/path.dart' as p;
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';
import 'package:vnu_core/widgets/field/vnu_date_picker_sheet.dart';
import 'package:vnu_noi_tru/widgets/nt_custom_dropdown.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

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
  late TextEditingController _identityNameController;
  late TextEditingController _identityIssuePlaceController;
  late TextEditingController _countryController;
  late TextEditingController _countryCodeController;
  late TextEditingController _nationalController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _vneidPermanentAddressController;
  late TextEditingController _permanentProvinceCodeController;
  late TextEditingController _permanentWardCodeController;
  late TextEditingController _contactAddressController;
  late TextEditingController _classNameController;
  late TextEditingController _facultyController;
  late TextEditingController _majorController;
  late TextEditingController _academicYearController;
  late TextEditingController _systemController;
  late TextEditingController _levelController;
  late TextEditingController _universityNameController;
  late TextEditingController _univIdController;
  late TextEditingController _priorityObjectNameController;
  late TextEditingController _temporaryAddressController;
  late TextEditingController _vneidTemporaryAddressController;
  late TextEditingController _temporaryProvinceCodeController;
  late TextEditingController _temporaryWardCodeController;
  late TextEditingController _ethnicityController;
  late TextEditingController _religionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _reasonController;

  String? _genderValue;
  String _identityType = 'CCCD';
  int? _studentType;
  final List<_FamilyMemberForm> _familyForms = <_FamilyMemberForm>[];

  @override
  void initState() {
    super.initState();

    _studentCodeController = TextEditingController();
    _fullNameController = TextEditingController();
    _dobController = TextEditingController();
    _genderController = TextEditingController();
    _cccdController = TextEditingController();
    _cccdIssueDateController = TextEditingController();
    _identityNameController = TextEditingController();
    _identityIssuePlaceController = TextEditingController();
    _countryController = TextEditingController();
    _countryCodeController = TextEditingController();
    _nationalController = TextEditingController();
    _permanentAddressController = TextEditingController();
    _vneidPermanentAddressController = TextEditingController();
    _permanentProvinceCodeController = TextEditingController();
    _permanentWardCodeController = TextEditingController();
    _contactAddressController = TextEditingController();
    _classNameController = TextEditingController();
    _facultyController = TextEditingController();
    _majorController = TextEditingController();
    _academicYearController = TextEditingController();
    _systemController = TextEditingController();
    _levelController = TextEditingController();
    _universityNameController = TextEditingController();
    _univIdController = TextEditingController();
    _priorityObjectNameController = TextEditingController();
    _temporaryAddressController = TextEditingController();
    _vneidTemporaryAddressController = TextEditingController();
    _temporaryProvinceCodeController = TextEditingController();
    _temporaryWardCodeController = TextEditingController();
    _ethnicityController = TextEditingController();
    _religionController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _reasonController = TextEditingController();

    _hydrateRegistrationDraft();
  }

  Future<void> _hydrateRegistrationDraft() async {
    final DormitoryRegistrationCubit cubit =
        context.read<DormitoryRegistrationCubit>();

    try {
      final DormitoryStudentDraft draft = await cubit.ensureStudentDraft();
      if (!mounted) return;

      _studentCodeController.text = draft.studentCode;
      _fullNameController.text = draft.fullName;
      _dobController.text = DormitoryDateCodec.normalize(draft.dob);
      _genderValue = draft.gender;
      _genderController.text = draft.gender ?? '';
      _cccdController.text = draft.identityNo;
      _cccdIssueDateController.text =
          DormitoryDateCodec.normalize(draft.identityIssueDate);
      final String rawIdentityType = (draft.identityType ?? '').toUpperCase();
      _identityType = const <String>{'CCCD', 'CMND', 'HC', 'GTK'}
              .contains(rawIdentityType)
          ? rawIdentityType
          : 'CCCD';
      _identityNameController.text = draft.identityName ?? '';
      _identityIssuePlaceController.text = draft.identityIssuePlace ?? '';
      _countryController.text = draft.country ?? '';
      _countryCodeController.text = draft.countryCode ?? '';
      _nationalController.text = draft.national ?? '';
      _permanentAddressController.text = draft.permanentAddress;
      _vneidPermanentAddressController.text = draft.vneidPermanentAddress ?? '';
      _permanentProvinceCodeController.text = draft.permanentProvinceCode ?? '';
      _permanentWardCodeController.text = draft.permanentWardCode ?? '';
      _contactAddressController.text = draft.contactAddress ?? '';
      _classNameController.text = draft.className;
      _facultyController.text = draft.faculty ?? '';
      _majorController.text = draft.major;
      _academicYearController.text = draft.academicYear;
      _systemController.text = draft.system;
      _levelController.text = draft.level;
      _universityNameController.text = draft.universityName;
      _univIdController.text = draft.univId?.toString() ?? '';
      _studentType = draft.studentType;
      _priorityObjectNameController.text = draft.priorityObjectName ?? '';
      _temporaryAddressController.text = draft.temporaryAddress;
      _vneidTemporaryAddressController.text = draft.vneidTemporaryAddress ?? '';
      _temporaryProvinceCodeController.text = draft.temporaryProvinceCode ?? '';
      _temporaryWardCodeController.text = draft.temporaryWardCode ?? '';
      _ethnicityController.text = draft.ethnicity ?? '';
      _religionController.text = draft.religion ?? '';
      _phoneController.text = draft.phone;
      _emailController.text = draft.email;
      _reasonController.text = draft.reasonStay ?? '';
      if (_priorityObjectNameController.text.trim().isEmpty &&
          cubit.selectedPriorityObjectNames.trim().isNotEmpty) {
        _priorityObjectNameController.text = cubit.selectedPriorityObjectNames;
      }

      for (final _FamilyMemberForm form in _familyForms) {
        form.dispose();
      }
      _familyForms
        ..clear()
        ..addAll(draft.familyMembers.map(_FamilyMemberForm.fromPayload));

      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text(AppErrorMapper.map(error).userMessage),
          ),
        );
    }
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _cccdController.dispose();
    _cccdIssueDateController.dispose();
    _identityNameController.dispose();
    _identityIssuePlaceController.dispose();
    _countryController.dispose();
    _countryCodeController.dispose();
    _nationalController.dispose();
    _permanentAddressController.dispose();
    _vneidPermanentAddressController.dispose();
    _permanentProvinceCodeController.dispose();
    _permanentWardCodeController.dispose();
    _contactAddressController.dispose();
    _classNameController.dispose();
    _facultyController.dispose();
    _majorController.dispose();
    _academicYearController.dispose();
    _systemController.dispose();
    _levelController.dispose();
    _universityNameController.dispose();
    _univIdController.dispose();
    _priorityObjectNameController.dispose();
    _temporaryAddressController.dispose();
    _vneidTemporaryAddressController.dispose();
    _temporaryProvinceCodeController.dispose();
    _temporaryWardCodeController.dispose();
    _ethnicityController.dispose();
    _religionController.dispose();
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

  Future<void> saveDataToCubit() async {
    final DormitoryRegistrationCubit cubit =
        context.read<DormitoryRegistrationCubit>();
    final DormitoryStudentDraft current = await cubit.ensureStudentDraft();

    final List<FamilyMemberPayload> members = _familyForms
        .map((_FamilyMemberForm item) => item.toPayload())
        .where((FamilyMemberPayload item) => item.fullName.trim().isNotEmpty)
        .toList();

    final DormitoryStudentDraft draft = current.copyWith(
      studentCode: _studentCodeController.text.trim(),
      fullName: _fullNameController.text.trim(),
      dob: DormitoryDateCodec.normalize(_dobController.text),
      gender: _genderValue,
      clearGender: _genderValue == null || _genderValue!.trim().isEmpty,
      identityNo: _cccdController.text.trim(),
      identityType: _identityType,
      identityName: _identityNameController.text.trim(),
      identityIssueDate:
          DormitoryDateCodec.normalize(_cccdIssueDateController.text),
      identityIssuePlace: _identityIssuePlaceController.text.trim(),
      country: _countryController.text.trim(),
      countryCode: _countryCodeController.text.trim(),
      national: _nationalController.text.trim(),
      permanentAddress: _permanentAddressController.text.trim(),
      vneidPermanentAddress: _vneidPermanentAddressController.text.trim(),
      permanentProvinceCode: _permanentProvinceCodeController.text.trim(),
      permanentWardCode: _permanentWardCodeController.text.trim(),
      contactAddress: _contactAddressController.text.trim(),
      className: _classNameController.text.trim(),
      faculty: _facultyController.text.trim(),
      major: _majorController.text.trim(),
      academicYear: _academicYearController.text.trim(),
      system: _systemController.text.trim(),
      level: _levelController.text.trim(),
      universityName: _universityNameController.text.trim(),
      univId: int.tryParse(_univIdController.text.trim()),
      clearUnivId: _univIdController.text.trim().isEmpty,
      studentType: _studentType,
      clearStudentType: _studentType == null,
      priorityObjectName: _priorityObjectNameController.text.trim(),
      temporaryAddress: _temporaryAddressController.text.trim(),
      vneidTemporaryAddress: _vneidTemporaryAddressController.text.trim(),
      temporaryProvinceCode: _temporaryProvinceCodeController.text.trim(),
      temporaryWardCode: _temporaryWardCodeController.text.trim(),
      ethnicity: _ethnicityController.text.trim(),
      religion: _religionController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      reasonStay: _reasonController.text.trim(),
      familyMembers: members,
    );

    await cubit.setStudentDraft(draft);
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller, {
    String title = 'Chọn ngày',
  }) async {
    DateTime initialDate = DateTime.tryParse(controller.text.trim()) ??
        DateTime.now();
    final DateTime now = DateUtils.dateOnly(DateTime.now());

    if (initialDate.isAfter(now)) {
      initialDate = now;
    }

    final DateTime? picked = await VnuDatePickerSheet.show(
      context: context,
      title: title,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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

      final File normalizedFile =
          await _compressImageToUploadStandard(originalFile);

      await _validateImageSize(normalizedFile);

      final File file = await DormitoryLocalFileStore.persist(
        normalizedFile,
        role: uploadSlot,
      );
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
        await DormitoryLocalFileStore.deleteIfManaged(cubit.avatarFile);
        cubit.selectAvatar(file);
      } else if (uploadSlot == 'cccd_front') {
        await DormitoryLocalFileStore.deleteIfManaged(cubit.cccdFrontFile);
        cubit.selectCCCDFront(file);
      } else if (uploadSlot == 'cccd_back') {
        await DormitoryLocalFileStore.deleteIfManaged(cubit.cccdBackFile);
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
                              'Mã sinh viên', _studentCodeController)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField(
                              'Họ và tên *', _fullNameController,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Nhập họ và tên'
                                  : null)),
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
                              onTap: () => _selectDate(
                                context,
                                _dobController,
                                title: 'Ngày sinh',
                              ),
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
                                  context,
                                  _cccdIssueDateController,
                                  title: 'Ngày cấp CCCD',
                                ),
                              validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Chọn ngày cấp'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: NtCustomDropdown<String>(
                              label: 'Loại giấy tờ',
                              hintText: 'Chọn loại giấy tờ',
                              value: _identityType,
                              items: const <String>['CCCD', 'CMND', 'HC', 'GTK'],
                              itemAsString: (String value) => value == 'HC'
                                  ? 'Hộ chiếu'
                                  : value == 'GTK'
                                      ? 'Giấy tờ khác'
                                      : value,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() => _identityType = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              'Tên giấy tờ',
                              _identityNameController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        'Nơi cấp giấy tờ',
                        _identityIssuePlaceController,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(child: _buildField('Mã quốc gia', _countryCodeController)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField('Quốc gia', _countryController)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(child: _buildField('Quốc tịch', _nationalController)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField('Dân tộc', _ethnicityController)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField('Tôn giáo', _religionController)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        'Địa chỉ thường trú *',
                        _permanentAddressController,
                        validator: (v) =>
                        v == null || v.isEmpty
                            ? 'Nhập địa chỉ thường trú'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        'Thường trú theo VNeID',
                        _vneidPermanentAddressController,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(child: _buildField('Mã tỉnh thường trú', _permanentProvinceCodeController)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField('Mã xã/phường thường trú', _permanentWardCodeController)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField('Địa chỉ liên hệ', _contactAddressController),
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
                                'Lớp', _classNameController)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildField(
                                'Ngành', _majorController)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildField(
                                'Năm học', _academicYearController)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(child: _buildField('Khoa/đơn vị', _facultyController)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: NtCustomDropdown<int>(
                                label: 'Loại người học',
                                hintText: 'Chọn loại',
                                value: _studentType,
                                items: const <int>[0, 1],
                                itemAsString: (int value) => value == 0 ? 'Học sinh' : 'Sinh viên',
                                onChanged: (int? value) => setState(() => _studentType = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildField(
                                'Hệ đào tạo', _systemController)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildField(
                                'Bậc đào tạo', _levelController)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(child: _buildField('Trường', _universityNameController)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildField(
                                'ID trường',
                                _univIdController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
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
                      _buildField('Tạm trú theo VNeID', _vneidTemporaryAddressController),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(child: _buildField('Mã tỉnh tạm trú', _temporaryProvinceCodeController)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildField('Mã xã/phường tạm trú', _temporaryWardCodeController)),
                        ],
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
                        'Tên đối tượng ưu tiên',
                        _priorityObjectNameController,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cubit.selectedPriorityObjectNames.isEmpty
                            ? 'Chưa chọn mã đối tượng ưu tiên.'
                            : 'Mã đối tượng ưu tiên đã chọn: ${cubit.selectedPriorityObjectNames}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.extraSmall,
                          color: Color(0xFF666B75),
                        ),
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
                        onRemove: () async {
                          await DormitoryLocalFileStore.deleteIfManaged(
                            cubit.cccdFrontFile,
                          );
                          if (!mounted) return;
                          setState(cubit.removeCCCDFront);
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
                        onRemove: () async {
                          await DormitoryLocalFileStore.deleteIfManaged(
                            cubit.cccdBackFile,
                          );
                          if (!mounted) return;
                          setState(cubit.removeCCCDBack);
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
                      VnuTextField(
                        controller: _reasonController,
                        label: 'Lý do đăng ký nội trú',
                        hintText: 'Nhập lý do...',
                        minLines: 3,
                        maxLines: 4,
                        maxLength: 500,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(() {}),
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
                          onPressed: () async {
                            await DormitoryLocalFileStore.deleteIfManaged(avatar);
                            if (!mounted) return;
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
    final bool requiredField = label.trim().endsWith('*');
    final String effectiveLabel =
        label.replaceFirst(RegExp(r'\s*\*$'), '').trim();

    return VnuTextField(
      controller: controller,
      label: effectiveLabel,
      requiredField: requiredField,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      trailing: icon == null
          ? null
          : const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF078B3E),
            ),
    );
  }

  Widget _buildDropdownField(String label, String? value,
      Function(String?) onChanged) {
    return NtCustomDropdown<String>(
      label: label,
      hintText: 'Chọn giới tính',
      value: value,
      items: const ['male', 'female'],
      itemAsString: (item) => item == 'male' ? 'Nam' : 'Nữ',
      validator: (String? selected) => selected == null
          ? 'Vui lòng chọn giới tính'
          : null,
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
                                onRemove: () async {
                                  await DormitoryLocalFileStore.deleteIfManaged(file);
                                  if (!mounted) return;
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
