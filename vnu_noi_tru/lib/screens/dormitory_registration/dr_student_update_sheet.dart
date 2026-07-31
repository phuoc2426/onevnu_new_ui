import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';

class DRStudentUpdateResult {
  final String identityNo;
  final String message;

  const DRStudentUpdateResult({
    required this.identityNo,
    required this.message,
  });
}

class DRStudentUpdateSheet extends StatefulWidget {
  final dynamic student;
  final dynamic accommodation;
  final String identityNo;

  const DRStudentUpdateSheet({
    super.key,
    required this.student,
    this.accommodation,
    required this.identityNo,
  });

  @override
  State<DRStudentUpdateSheet> createState() =>
      _DRStudentUpdateSheetState();
}

class _DRStudentUpdateSheetState extends State<DRStudentUpdateSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DormitoryRegistrationRepository _repository =
      DormitoryRegistrationRepository();
  final ImagePicker _imagePicker = ImagePicker();

  static const int _maxAvatarSizeBytes = 5 * 1024 * 1024;
  static const int _defaultMaxImageSide = 1600;
  static const int _fallbackMaxImageSide = 1280;
  static const int _defaultImageQuality = 82;
  static const int _minImageQuality = 55;

  File? _avatarFile;
  bool _isImagePickerActive = false;
  late final String _existingAvatarUrl;

  final List<File> _priorityDocumentFiles = <File>[];
  late final List<_ExistingPriorityDocument> _existingPriorityDocuments;

  final List<PriorityObjectModel> _priorityObjects = <PriorityObjectModel>[];
  final List<PriorityObjectModel> _selectedPriorityObjects =
      <PriorityObjectModel>[];
  late final Set<int> _initialPriorityObjectIds;
  late final Set<String> _initialPriorityObjectNames;
  bool _loadingPriorityObjects = false;
  String? _priorityObjectsError;

  late final TextEditingController _studentCodeController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late final TextEditingController _identityNameController;
  late final TextEditingController _identityNoController;
  late final TextEditingController _identityIssueDateController;
  late final TextEditingController _identityIssuePlaceController;

  late final TextEditingController _classNameController;
  late final TextEditingController _facultyController;
  late final TextEditingController _majorController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _systemController;
  late final TextEditingController _levelController;
  late final TextEditingController _universityController;

  late final TextEditingController _countryController;
  late final TextEditingController _nationalController;

  late final TextEditingController _permanentAddressController;
  late final TextEditingController _contactAddressController;
  late final TextEditingController _vneidPermanentAddressController;
  late final TextEditingController _permanentProvinceCodeController;
  late final TextEditingController _permanentWardCodeController;

  late final TextEditingController _temporaryAddressController;
  late final TextEditingController _vneidTemporaryAddressController;
  late final TextEditingController _temporaryProvinceCodeController;
  late final TextEditingController _temporaryWardCodeController;

  late final TextEditingController _reasonStayController;

  String _gender = 'male';
  String _identityType = 'CCCD';
  bool _submitting = false;

  final List<_StudentFamilyMemberForm> _familyForms =
      <_StudentFamilyMemberForm>[];

  @override
  void initState() {
    super.initState();

    _existingPriorityDocuments =
        _readExistingPriorityDocuments(widget.accommodation);
    _initialPriorityObjectIds = _readExistingPriorityObjectIds();
    _initialPriorityObjectNames = _readExistingPriorityObjectNames();

    _existingAvatarUrl = _resolveAvatarUrl(
      _readText(
        widget.student,
        const <String>['avatar', 'avatar_url', 'avatarUrl'],
        (dynamic object) => object.avatar,
      ),
    );

    _studentCodeController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['student_code', 'studentCode'],
        (dynamic object) => object.studentCode,
      ),
    );

    _fullNameController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['full_name', 'fullName'],
        (dynamic object) => object.fullName,
      ),
    );

    _dobController = TextEditingController(
      text: _readDateText(
        _readValue(
          widget.student,
          const <String>['dob', 'date_of_birth', 'dateOfBirth'],
          (dynamic object) => object.dob,
        ),
      ),
    );

    final String rawGender = _readText(
      widget.student,
      const <String>['gender'],
      (dynamic object) => object.gender,
    ).toLowerCase();
    _gender = rawGender == 'female' || rawGender == 'nữ' ? 'female' : 'male';

    _phoneController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['phone_number', 'phoneNumber', 'phone'],
        (dynamic object) => object.phone,
      ),
    );

    _emailController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['email'],
        (dynamic object) => object.email,
      ),
    );

    final String rawIdentityType = _readText(
      widget.student,
      const <String>['identity_type', 'identityType'],
      (dynamic object) => object.identityType,
    ).toUpperCase();
    if (const <String>{'CCCD', 'CMND', 'HC', 'GTK'}
        .contains(rawIdentityType)) {
      _identityType = rawIdentityType;
    }

    _identityNameController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['identity_name', 'identityName'],
        (dynamic object) => object.identityName,
      ),
    );

    _identityNoController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['identity_no', 'identityNo', 'cccd'],
        (dynamic object) => object.cccd,
      ).isNotEmpty
          ? _readText(
              widget.student,
              const <String>['identity_no', 'identityNo', 'cccd'],
              (dynamic object) => object.cccd,
            )
          : widget.identityNo,
    );

    _identityIssueDateController = TextEditingController(
      text: _readDateText(
        _readValue(
          widget.student,
          const <String>[
            'identity_issue_date',
            'identityIssueDate',
            'cccd_issue_date',
          ],
          (dynamic object) => object.cccdIssueDate,
        ),
      ),
    );

    _identityIssuePlaceController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>[
          'identity_issue_place',
          'identityIssuePlace',
        ],
        (dynamic object) => object.identityIssuePlace,
      ),
    );

    _classNameController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['class', 'class_name', 'className'],
        (dynamic object) => object.className,
      ),
    );
    _facultyController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['faculty'],
        (dynamic object) => object.faculty,
      ),
    );
    _majorController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['major'],
        (dynamic object) => object.major,
      ),
    );
    _academicYearController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['academic_year', 'academicYear'],
        (dynamic object) => object.academicYear,
      ),
    );
    _systemController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['system'],
        (dynamic object) => object.system,
      ),
    );
    _levelController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['level'],
        (dynamic object) => object.level,
      ),
    );
    _universityController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>[
          'university',
          'university_name',
          'universityName',
        ],
        (dynamic object) => object.university,
      ),
    );

    _countryController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['country'],
        (dynamic object) => object.country,
      ),
    );

    _nationalController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['national', 'nationality'],
        (dynamic object) => object.national,
      ),
    );

    _permanentAddressController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['permanent_address', 'permanentAddress', 'hometown'],
        (dynamic object) => object.hometown,
      ),
    );

    _contactAddressController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['contact_address', 'contactAddress'],
        (dynamic object) => object.contactAddress,
      ),
    );

    _vneidPermanentAddressController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>[
          'vneid_permanent_address',
          'vneidPermanentAddress',
        ],
        (dynamic object) => object.vneidPermanentAddress,
      ),
    );

    _permanentProvinceCodeController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>[
          'permanent_province_code',
          'permanentProvinceCode',
        ],
        (dynamic object) => object.permanentProvinceCode,
      ),
    );

    _permanentWardCodeController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['permanent_ward_code', 'permanentWardCode'],
        (dynamic object) => object.permanentWardCode,
      ),
    );

    _temporaryAddressController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['temporary_address', 'temporaryAddress'],
        (dynamic object) => object.temporaryAddress,
      ),
    );

    _vneidTemporaryAddressController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>[
          'vneid_temporary_address',
          'vneidTemporaryAddress',
        ],
        (dynamic object) => object.vneidTemporaryAddress,
      ),
    );

    _temporaryProvinceCodeController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>[
          'temporary_province_code',
          'temporaryProvinceCode',
        ],
        (dynamic object) => object.temporaryProvinceCode,
      ),
    );

    _temporaryWardCodeController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['temporary_ward_code', 'temporaryWardCode'],
        (dynamic object) => object.temporaryWardCode,
      ),
    );

    _reasonStayController = TextEditingController(
      text: _readText(
        widget.student,
        const <String>['reason_stay', 'reasonStay'],
        (dynamic object) => object.reasonStay,
      ),
    );

    _familyForms.addAll(_readFamilyMembers(widget.student));
    _loadPriorityObjects();
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _identityNameController.dispose();
    _identityNoController.dispose();
    _identityIssueDateController.dispose();
    _identityIssuePlaceController.dispose();
    _classNameController.dispose();
    _facultyController.dispose();
    _majorController.dispose();
    _academicYearController.dispose();
    _systemController.dispose();
    _levelController.dispose();
    _universityController.dispose();
    _countryController.dispose();
    _nationalController.dispose();
    _permanentAddressController.dispose();
    _contactAddressController.dispose();
    _vneidPermanentAddressController.dispose();
    _permanentProvinceCodeController.dispose();
    _permanentWardCodeController.dispose();
    _temporaryAddressController.dispose();
    _vneidTemporaryAddressController.dispose();
    _temporaryProvinceCodeController.dispose();
    _temporaryWardCodeController.dispose();
    _reasonStayController.dispose();

    for (final _StudentFamilyMemberForm form in _familyForms) {
      form.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.94;

    return Theme(
      data: _buildGreenFormTheme(context),
      child: Material(
        color: const Color(0xFFF6F8F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Column(
              children: <Widget>[
                _buildHeader(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        24 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        children: <Widget>[
                          _buildAvatarCard(),
                          const SizedBox(height: 12),
                          _buildPersonalCard(),
                          const SizedBox(height: 12),
                          _buildIdentityCard(),
                          const SizedBox(height: 12),
                          _buildAcademicCard(),
                          const SizedBox(height: 12),
                          _buildContactPriorityCard(),
                          const SizedBox(height: 12),
                          _buildFamilyCard(),
                          const SizedBox(height: 12),
                          _buildPriorityDocumentsCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(),
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
      scaffoldBackgroundColor: const Color(0xFFF6F8F7),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: green,
        selectionColor: Color(0x33078B3E),
        selectionHandleColor: green,
      ),
      splashColor: const Color(0x14078B3E),
      highlightColor: const Color(0x0F078B3E),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 8),
      child: Column(
        children: <Widget>[
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD5D8DE),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Cập nhật thông tin sinh viên',
                  style: TextStyle(
                    fontSize: AppFontSizes.medium,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111318),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: _submitting ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard() {
    final bool hasLocalAvatar = _avatarFile != null;
    final bool hasRemoteAvatar = _existingAvatarUrl.isNotEmpty;

    Widget avatarWidget;
    if (hasLocalAvatar) {
      avatarWidget = Image.file(
        _avatarFile!,
        fit: BoxFit.cover,
      );
    } else if (hasRemoteAvatar) {
      avatarWidget = Image.network(
        _existingAvatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
      );
    } else {
      avatarWidget = _buildAvatarPlaceholder();
    }

    return _sectionCard(
      icon: Icons.badge_outlined,
      title: 'Ảnh thẻ sinh viên',
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: hasLocalAvatar
                  ? () => _showLocalAvatarPreview(_avatarFile!)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 86,
                  height: 108,
                  child: avatarWidget,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Ảnh chân dung rõ mặt, nền sáng. Ảnh được chuyển sang JPG và nén dưới 5 MB.',
                    style: TextStyle(
                      fontSize: AppFontSizes.extraSmall,
                      color: Color(0xFF666B75),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _pickAvatar,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF078B3E),
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      hasLocalAvatar || hasRemoteAvatar
                          ? Icons.refresh_rounded
                          : Icons.add_a_photo_outlined,
                      size: 18,
                    ),
                    label: Text(
                      hasLocalAvatar || hasRemoteAvatar
                          ? 'Đổi ảnh thẻ'
                          : 'Chọn ảnh thẻ',
                    ),
                  ),
                  if (hasLocalAvatar) ...<Widget>[
                    const SizedBox(height: 7),
                    TextButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _avatarFile = null),
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('Giữ ảnh hiện tại'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFF4F7F5),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.person_outline_rounded, size: 36, color: Color(0xFF078B3E)),
          SizedBox(height: 5),
          Text(
            'Ảnh 3x4',
            style: TextStyle(
              fontSize: AppFontSizes.extraSmall,
              color: Color(0xFF666B75),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    if (_isImagePickerActive) {
      debugPrint('[DORMITORY-AVATAR-PICKER] ignored duplicate request');
      _showError(
        'Trình chọn ảnh đang mở. Vui lòng chọn hoặc đóng cửa sổ hiện tại trước.',
      );
      return;
    }

    _isImagePickerActive = true;

    try {
      final XFile? selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _defaultImageQuality,
        maxWidth: _defaultMaxImageSide.toDouble(),
        maxHeight: _defaultMaxImageSide.toDouble(),
      );
      if (selected == null) return;

      final File compressed = await _compressAvatar(File(selected.path));
      if (!mounted) return;
      setState(() => _avatarFile = compressed);
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[DORMITORY-AVATAR-PICKER-ERROR] '
        'code=${error.code}, message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError(
        error.code == 'already_active'
            ? 'Trình chọn ảnh đã được mở. Vui lòng đóng cửa sổ chọn ảnh cũ rồi thử lại.'
            : 'Không thể mở thư viện ảnh: ${error.message ?? error.code}',
      );
    } catch (error, stackTrace) {
      debugPrint('[DORMITORY-AVATAR-PICKER-ERROR] $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isImagePickerActive = false;
    }
  }

  Future<File> _compressAvatar(File originalFile) async {
    if (!await originalFile.exists()) {
      throw Exception('Không tìm thấy ảnh đã chọn trên thiết bị.');
    }

    final Directory tempDirectory = await getTemporaryDirectory();
    int quality = _defaultImageQuality;
    int maxSide = _defaultMaxImageSide;
    File? lastOutput;

    while (quality >= _minImageQuality) {
      final String outputPath = p.join(
        tempDirectory.path,
        'noi_tru_avatar_${DateTime.now().microsecondsSinceEpoch}_${quality}_${maxSide}.jpg',
      );

      final XFile? output = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        outputPath,
        quality: quality,
        minWidth: maxSide,
        minHeight: maxSide,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (output == null) {
        throw Exception('Không thể xử lý ảnh thẻ. Vui lòng chọn ảnh JPG hoặc PNG khác.');
      }

      lastOutput = File(output.path);
      if (await lastOutput.length() <= _maxAvatarSizeBytes) {
        return lastOutput;
      }

      quality -= 8;
      if (quality <= 66) maxSide = _fallbackMaxImageSide;
    }

    if (lastOutput == null || await lastOutput.length() > _maxAvatarSizeBytes) {
      throw Exception('Ảnh thẻ không được vượt quá 5 MB.');
    }
    return lastOutput;
  }

  void _showLocalAvatarPreview(File file) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(18),
          child: Stack(
            children: <Widget>[
              InteractiveViewer(
                child: Center(child: Image.file(file, fit: BoxFit.contain)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolveAvatarUrl(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) return '';
    final Uri? uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme) return normalized;
    return normalized.startsWith('/')
        ? 'https://ktx.sohatech.vn$normalized'
        : 'https://ktx.sohatech.vn/$normalized';
  }

  Widget _buildPersonalCard() {
    return _sectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Thông tin sinh viên',
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _studentCodeController,
                label: 'Mã sinh viên',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _fullNameController,
                label: 'Họ và tên *',
                maxLength: 255,
                validator: _requiredValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _dateField(
                controller: _dobController,
                label: 'Ngày sinh *',
                validator: _requiredValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gender,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                menuMaxHeight: 320,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF078B3E),
                ),
                style: const TextStyle(
                  fontSize: AppFontSizes.mediumSmall,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111318),
                ),
                decoration: _inputDecoration('Giới tính *'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                ],
                onChanged: _submitting
                    ? null
                    : (String? value) {
                        if (value != null) {
                          setState(() => _gender = value);
                        }
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentityCard() {
    return _sectionCard(
      icon: Icons.badge_outlined,
      title: 'Giấy tờ tùy thân',
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _identityType,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                menuMaxHeight: 320,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF078B3E),
                ),
                style: const TextStyle(
                  fontSize: AppFontSizes.mediumSmall,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111318),
                ),
                decoration: _inputDecoration('Loại giấy tờ'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'CCCD', child: Text('CCCD')),
                  DropdownMenuItem(value: 'CMND', child: Text('CMND')),
                  DropdownMenuItem(value: 'HC', child: Text('Hộ chiếu')),
                  DropdownMenuItem(value: 'GTK', child: Text('Giấy tờ khác')),
                ],
                onChanged: _submitting
                    ? null
                    : (String? value) {
                        if (value != null) {
                          setState(() => _identityType = value);
                        }
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _identityNameController,
                label: 'Tên giấy tờ',
                maxLength: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _identityNoController,
                label: 'Số CCCD/giấy tờ *',
                maxLength: 50,
                validator: _requiredValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateField(
                controller: _identityIssueDateController,
                label: 'Ngày cấp',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _field(
          controller: _identityIssuePlaceController,
          label: 'Nơi cấp',
          maxLength: 255,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _permanentAddressController,
          label: 'Quê quán/địa chỉ thường trú',
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _vneidPermanentAddressController,
          label: 'Địa chỉ thường trú theo VNeID',
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _countryController,
                label: 'Mã quốc gia',
                maxLength: 10,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _nationalController,
                label: 'Quốc tịch',
                maxLength: 50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicCard() {
    return _sectionCard(
      icon: Icons.school_outlined,
      title: 'Thông tin học tập',
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _classNameController,
                label: 'Lớp',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(
                controller: _majorController,
                label: 'Ngành',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(
                controller: _academicYearController,
                label: 'Năm học',
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _facultyController,
                label: 'Khoa/đơn vị',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _systemController,
                label: 'Hệ đào tạo',
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _levelController,
                label: 'Bậc đào tạo',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _universityController,
                label: 'Trường',
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactPriorityCard() {
    return _sectionCard(
      icon: Icons.phone_outlined,
      title: 'Liên hệ & ưu tiên',
      children: <Widget>[
        _field(
          controller: _temporaryAddressController,
          label: 'Địa chỉ tạm trú',
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _vneidTemporaryAddressController,
          label: 'Địa chỉ tạm trú theo VNeID',
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _contactAddressController,
          label: 'Địa chỉ liên hệ',
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _phoneController,
                label: 'Số điện thoại *',
                keyboardType: TextInputType.phone,
                maxLength: 20,
                validator: _requiredValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _emailController,
                label: 'Email *',
                keyboardType: TextInputType.emailAddress,
                maxLength: 255,
                validator: _emailValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Đối tượng ưu tiên',
          style: TextStyle(
            fontSize: AppFontSizes.font11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        _buildPriorityObjectSelector(),
      ],
    );
  }

  Widget _buildPriorityObjectSelector() {
    if (_loadingPriorityObjects) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF078B3E),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Đang tải đối tượng ưu tiên...',
              style: TextStyle(
                fontSize: AppFontSizes.small,
                color: Color(0xFF666B75),
              ),
            ),
          ],
        ),
      );
    }

    if (_priorityObjectsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEA580C),
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _priorityObjectsError!,
                style: const TextStyle(
                  fontSize: AppFontSizes.extraSmall,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
            TextButton(
              onPressed: _submitting ? null : _loadPriorityObjects,
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    if (_priorityObjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E6EB)),
        ),
        child: const Text(
          'Chưa có dữ liệu đối tượng ưu tiên.',
          style: TextStyle(
            fontSize: AppFontSizes.small,
            color: Color(0xFF666B75),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_selectedPriorityObjects.isNotEmpty) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBEAD6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Đã chọn',
                  style: TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF47614F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _selectedPriorityObjects
                      .map(
                        (PriorityObjectModel item) => InputChip(
                          label: Text(item.name ?? 'Đối tượng ưu tiên'),
                          onDeleted: _submitting
                              ? null
                              : () => _togglePriorityObject(item),
                          deleteIcon: const Icon(
                            Icons.close_rounded,
                            size: 17,
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFB9DDC5)),
                          labelStyle: const TextStyle(
                            color: Color(0xFF078B3E),
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSizes.extraSmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        ..._priorityObjects.map((PriorityObjectModel item) {
          final bool selected = _isPriorityObjectSelected(item);
          final String itemKey =
              (item.id ?? item.name ?? item.hashCode).toString();

          return AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (
                Widget child,
                Animation<double> animation,
              ) {
                final Animation<Offset> slideAnimation = Tween<Offset>(
                  begin: const Offset(-0.14, 0),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
              child: selected
                  ? SizedBox.shrink(
                      key: ValueKey<String>('selected-$itemKey'),
                    )
                  : Padding(
                      key: ValueKey<String>('available-$itemKey'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: _submitting
                            ? null
                            : () => _togglePriorityObject(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE3E6EB),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Checkbox(
                                value: false,
                                activeColor: const Color(0xFF078B3E),
                                checkColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                onChanged: _submitting
                                    ? null
                                    : (_) => _togglePriorityObject(item),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.name ?? 'Đối tượng ưu tiên',
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.small,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111318),
                                      ),
                                    ),
                                    if ((item.description ?? '')
                                        .trim()
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description!.trim(),
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.extraSmall,
                                          color: Color(0xFF666B75),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriorityDocumentsCard() {
    final bool hasExisting = _existingPriorityDocuments.isNotEmpty;
    final bool hasSelected = _priorityDocumentFiles.isNotEmpty;

    return _sectionCard(
      icon: Icons.verified_user_outlined,
      title: 'Minh chứng & lý do',
      trailing: OutlinedButton.icon(
        onPressed: _submitting ? null : _pickPriorityDocument,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF078B3E),
          backgroundColor: const Color(0xFFEAF7EF),
          side: const BorderSide(color: Color(0xFFBDE7CB)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
        label: Text(hasSelected ? 'Thêm ảnh' : 'Chọn ảnh'),
      ),
      children: <Widget>[
        const Text(
          'Giấy tờ ưu tiên được tải bằng API chung giống ảnh CCCD. Chỉ bổ sung khi sinh viên thuộc đối tượng ưu tiên.',
          style: TextStyle(
            fontSize: AppFontSizes.extraSmall,
            color: Color(0xFF666B75),
            height: 1.4,
          ),
        ),
        if (!hasExisting && !hasSelected) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E8E5)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chưa có giấy tờ ưu tiên. Có thể bỏ qua phần này.',
                    style: TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: Color(0xFF666B75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasExisting) ...<Widget>[
          const SizedBox(height: 14),
          const Text(
            'Tài liệu đã có',
            style: TextStyle(
              fontSize: AppFontSizes.font11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          ..._existingPriorityDocuments.map(_buildExistingPriorityDocument),
        ],
        if (hasSelected) ...<Widget>[
          const SizedBox(height: 14),
          const Text(
            'Ảnh sẽ tải lên khi bấm Lưu cập nhật',
            style: TextStyle(
              fontSize: AppFontSizes.font11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF078B3E),
            ),
          ),
          const SizedBox(height: 8),
          ..._priorityDocumentFiles.asMap().entries.map(
                (MapEntry<int, File> entry) =>
                    _buildSelectedPriorityDocument(entry.key, entry.value),
              ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Lý do lưu trú',
          style: TextStyle(
            fontSize: AppFontSizes.font11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        _field(
          controller: _reasonStayController,
          label: 'Nhập lý do lưu trú',
          maxLines: 3,
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildExistingPriorityDocument(_ExistingPriorityDocument document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E7E3)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF078B3E),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              document.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          if (document.url.isNotEmpty)
            IconButton(
              tooltip: 'Xem ảnh',
              onPressed: () => _showRemoteImagePreview(document.url),
              icon: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFF078B3E),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedPriorityDocument(int index, File file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBDE7CB)),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.file(
              file,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 46,
                color: const Color(0xFFEAF7EF),
                child: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF078B3E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.basename(file.path),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Xem ảnh',
            onPressed: () => _showLocalAvatarPreview(file),
            icon: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF078B3E),
            ),
          ),
          IconButton(
            tooltip: 'Xóa ảnh',
            onPressed: _submitting
                ? null
                : () {
                    setState(() => _priorityDocumentFiles.removeAt(index));
                  },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPriorityDocument() async {
    if (_isImagePickerActive) {
      _showError(
        'Trình chọn ảnh đang mở. Vui lòng chọn hoặc đóng cửa sổ hiện tại trước.',
      );
      return;
    }

    _isImagePickerActive = true;
    try {
      final XFile? selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _defaultImageQuality,
        maxWidth: _defaultMaxImageSide.toDouble(),
        maxHeight: _defaultMaxImageSide.toDouble(),
      );
      if (selected == null) return;

      final File compressed = await _compressAvatar(File(selected.path));
      final int size = await compressed.length();
      final bool duplicate = await _hasDuplicatePriorityDocument(
        compressed,
        size,
      );
      if (duplicate) {
        if (!mounted) return;
        _showError('Ảnh này đã được chọn trước đó.');
        return;
      }

      if (!mounted) return;
      setState(() => _priorityDocumentFiles.add(compressed));
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[DORMITORY-PRIORITY-PICKER-ERROR] '
        'code=${error.code}, message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError(
        error.code == 'already_active'
            ? 'Trình chọn ảnh đã được mở. Vui lòng đóng cửa sổ chọn ảnh cũ rồi thử lại.'
            : 'Không thể mở thư viện ảnh: ${error.message ?? error.code}',
      );
    } catch (error, stackTrace) {
      debugPrint('[DORMITORY-PRIORITY-PICKER-ERROR] $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isImagePickerActive = false;
    }
  }

  Future<bool> _hasDuplicatePriorityDocument(File candidate, int size) async {
    for (final File current in _priorityDocumentFiles) {
      if (current.path == candidate.path) return true;
      if (p.basename(current.path) == p.basename(candidate.path) &&
          await current.length() == size) {
        return true;
      }
    }
    return false;
  }

  void _showRemoteImagePreview(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.black,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.network(
                    _resolveAvatarUrl(url),
                    fit: BoxFit.contain,
                    loadingBuilder: (_, Widget child, ImageChunkEvent? event) {
                      if (event == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        'Không thể hiển thị tài liệu',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressCard() {
    return _sectionCard(
      icon: Icons.location_on_outlined,
      title: 'Địa chỉ và thông tin lưu trú',
      children: <Widget>[
        _field(
          controller: _permanentAddressController,
          label: 'Địa chỉ thường trú',
          maxLength: 500,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _vneidPermanentAddressController,
          label: 'Địa chỉ thường trú VNeID',
          maxLength: 500,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _permanentProvinceCodeController,
                label: 'Mã tỉnh thường trú',
                maxLength: 50,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _permanentWardCodeController,
                label: 'Mã xã thường trú',
                maxLength: 50,
              ),
            ),
          ],
        ),
        const Divider(height: 26),
        _field(
          controller: _temporaryAddressController,
          label: 'Địa chỉ tạm trú',
          maxLength: 500,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _vneidTemporaryAddressController,
          label: 'Địa chỉ tạm trú VNeID',
          maxLength: 500,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _field(
                controller: _temporaryProvinceCodeController,
                label: 'Mã tỉnh tạm trú',
                maxLength: 50,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _temporaryWardCodeController,
                label: 'Mã xã tạm trú',
                maxLength: 50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _field(
          controller: _reasonStayController,
          label: 'Lý do lưu trú',
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildFamilyCard() {
    return _sectionCard(
      icon: Icons.family_restroom_rounded,
      title: 'Thông tin gia đình',
      trailing: TextButton.icon(
        onPressed: _submitting ? null : _addFamilyMember,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Thêm'),
      ),
      children: <Widget>[
        const Text(
          'Khi lưu, danh sách dưới đây sẽ thay thế toàn bộ danh sách người thân hiện có.',
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Chưa có thông tin bố, mẹ hoặc người giám hộ.',
              style: TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF666B75),
              ),
            ),
          ),
        ] else
          ..._familyForms.asMap().entries.map(
                (MapEntry<int, _StudentFamilyMemberForm> entry) =>
                    _buildFamilyEditor(entry.key, entry.value),
              ),
      ],
    );
  }

  Widget _buildFamilyEditor(
    int index,
    _StudentFamilyMemberForm form,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E6EB)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: form.relationship,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 320,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF078B3E),
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111318),
                  ),
                  decoration: _inputDecoration('Quan hệ *'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'father', child: Text('Bố')),
                    DropdownMenuItem(value: 'mother', child: Text('Mẹ')),
                    DropdownMenuItem(
                      value: 'guardian',
                      child: Text('Người giám hộ'),
                    ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (String? value) {
                          if (value != null) {
                            setState(() => form.relationship = value);
                          }
                        },
                ),
              ),
              IconButton(
                tooltip: 'Xóa người thân',
                onPressed: _submitting ? null : () => _removeFamilyMember(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(
            controller: form.fullNameController,
            label: 'Họ và tên *',
            maxLength: 255,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _field(
                  controller: form.birthYearController,
                  label: 'Năm sinh',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 4,
                  validator: _birthYearValidator,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  controller: form.phoneController,
                  label: 'Số điện thoại',
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(
            controller: form.occupationController,
            label: 'Nghề nghiệp',
            maxLength: 255,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE3E6EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: AppTheme.colorMain),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppFontSizes.mediumSmall,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_submitting,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      cursorColor: const Color(0xFF078B3E),
      style: const TextStyle(
        fontSize: AppFontSizes.mediumSmall,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111318),
        height: 1.35,
      ),
      decoration: _inputDecoration(label).copyWith(
        counterText: '',
        fillColor: readOnly ? const Color(0xFFF4F6F5) : Colors.white,
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: !_submitting,
      validator: validator,
      onTap: () => _selectDate(controller),
      cursorColor: const Color(0xFF078B3E),
      style: const TextStyle(
        fontSize: AppFontSizes.mediumSmall,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111318),
      ),
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: Color(0xFF078B3E),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE3DF)),
    );

    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(
        fontSize: AppFontSizes.font11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: AppFontSizes.font11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF078B3E),
      ),
      hintStyle: const TextStyle(
        fontSize: AppFontSizes.mediumSmall,
        color: Color(0xFF9CA3AF),
      ),
      errorStyle: const TextStyle(
        fontSize: AppFontSizes.extraSmall,
        color: Color(0xFFDC2626),
      ),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E6EB))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.colorMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_submitting ? 'Đang cập nhật...' : 'Lưu cập nhật'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    final DateTime? parsed = DateTime.tryParse(controller.text.trim());
    if (parsed != null) initialDate = parsed;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: _buildGreenFormTheme(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selected != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(selected);
    }
  }

  void _addFamilyMember() {
    setState(() {
      _familyForms.add(_StudentFamilyMemberForm.empty());
    });
  }

  void _removeFamilyMember(int index) {
    final _StudentFamilyMemberForm removed = _familyForms.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final String originalIdentityNo = widget.identityNo.trim();
    final String updatedIdentityNo = _identityNoController.text.trim();

    if (originalIdentityNo.isEmpty) {
      _showError('Không tìm thấy CCCD hoặc mã sinh viên để cập nhật');
      return;
    }

    setState(() => _submitting = true);

    try {
      final List<int> selectedPriorityIds = _selectedPriorityObjects
          .map((PriorityObjectModel item) => item.id)
          .whereType<int>()
          .toSet()
          .toList();
      final String selectedPriorityNames = _selectedPriorityObjectNames;

      final Map<String, dynamic> data = <String, dynamic>{
        'full_name': _textOrNull(_fullNameController),
        'gender': _gender,
        'dob': _dateToApiOrNull(_dobController.text),
        'phone_number': _textOrNull(_phoneController),
        'email': _textOrNull(_emailController),
        'identity_type': _identityType,
        'identity_name': _textOrNull(_identityNameController),
        'identity_no': updatedIdentityNo.isEmpty ? null : updatedIdentityNo,
        'identity_issue_date':
            _dateToApiOrNull(_identityIssueDateController.text),
        'identity_issue_place': _textOrNull(_identityIssuePlaceController),
        'country': _textOrNull(_countryController),
        'national': _textOrNull(_nationalController),
        'permanent_address': _textOrNull(_permanentAddressController),
        'contact_address': _textOrNull(_contactAddressController),
        'vneid_permanent_address':
            _textOrNull(_vneidPermanentAddressController),
        'permanent_province_code':
            _textOrNull(_permanentProvinceCodeController),
        'permanent_ward_code':
            _textOrNull(_permanentWardCodeController),
        'temporary_address': _textOrNull(_temporaryAddressController),
        'vneid_temporary_address':
            _textOrNull(_vneidTemporaryAddressController),
        'temporary_province_code':
            _textOrNull(_temporaryProvinceCodeController),
        'temporary_ward_code':
            _textOrNull(_temporaryWardCodeController),
        'reason_stay': _textOrNull(_reasonStayController),
        // Gửi kèm để backend mới có thể đồng bộ lựa chọn ưu tiên.
        // Với backend cũ chưa khai báo hai field này, Laravel sẽ bỏ qua.
        'priority_object_ids': selectedPriorityIds,
        'priority_object_name':
            selectedPriorityNames.isEmpty ? null : selectedPriorityNames,
        // API quy định: gửi key này sẽ thay toàn bộ danh sách hiện tại.
        'family_members': _familyForms
            .map((_StudentFamilyMemberForm item) => item.toPayload().toJson())
            .toList(),
      };

      final bool hasUploadFiles =
          _avatarFile != null || _priorityDocumentFiles.isNotEmpty;
      final RegistrationStudentPayload? uploadStudent = hasUploadFiles
          ? _buildUploadStudentPayload(
              identityNo: updatedIdentityNo.isEmpty
                  ? originalIdentityNo
                  : updatedIdentityNo,
            )
          : null;

      if (_avatarFile != null && uploadStudent != null) {
        final UploadedAttachmentListResponse avatarResponse =
            await _repository.uploadAvatar(
          student: uploadStudent,
          file: _avatarFile!,
        );
        if (avatarResponse.success != true &&
            (avatarResponse.data == null || avatarResponse.data!.isEmpty)) {
          throw Exception('Không tải được ảnh thẻ sinh viên');
        }
      }

      final List<Object> uploadedPriorityAttachmentIds = <Object>[];

      if (_priorityDocumentFiles.isNotEmpty && uploadStudent != null) {
        final List<File> filesToUpload =
            List<File>.from(_priorityDocumentFiles);
        for (int index = 0; index < filesToUpload.length; index++) {
          final UploadedAttachmentListResponse proofResponse =
              await _repository.uploadPriorityDocuments(
            student: uploadStudent,
            files: <File>[filesToUpload[index]],
          );

          if (proofResponse.success != true &&
              (proofResponse.data == null || proofResponse.data!.isEmpty)) {
            throw Exception(
              'Không tải được giấy tờ ưu tiên ${index + 1}/${filesToUpload.length}',
            );
          }

          uploadedPriorityAttachmentIds.addAll(
            (proofResponse.data ?? <UploadedAttachmentModel>[])
                .map((UploadedAttachmentModel item) => item.id)
                .whereType<Object>(),
          );
        }
      }

      if (uploadedPriorityAttachmentIds.isNotEmpty) {
        // Backend cập nhật mới có thể dùng các ID này để gắn giấy tờ vào hồ sơ.
        data['attachment_file_ids'] = uploadedPriorityAttachmentIds;
      }

      final Map<String, dynamic> response = await _repository.updateStudent(
        identityNo: originalIdentityNo,
        data: data,
      );

      if (!mounted) return;

      final String baseMessage =
          response['message']?.toString().trim().isNotEmpty == true
              ? response['message'].toString()
              : 'Cập nhật thông tin sinh viên thành công.';
      final String uploadMessage = _priorityDocumentFiles.isEmpty
          ? ''
          : ' Đã tải lên ${_priorityDocumentFiles.length} giấy tờ ưu tiên.';
      final String priorityMessage = selectedPriorityNames.isEmpty
          ? ''
          : ' Đối tượng ưu tiên đã chọn: $selectedPriorityNames.';
      final String message = '$baseMessage$uploadMessage$priorityMessage';

      Navigator.pop(
        context,
        DRStudentUpdateResult(
          identityNo: updatedIdentityNo.isEmpty
              ? originalIdentityNo
              : updatedIdentityNo,
          message: message,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Exception: ', ''));
      setState(() => _submitting = false);
    }
  }

  RegistrationStudentPayload _buildUploadStudentPayload({
    required String identityNo,
  }) {
    return RegistrationStudentPayload(
      studentCode: _readText(
        widget.student,
        const <String>['student_code', 'studentCode'],
        (dynamic object) => object.studentCode,
      ),
      fullName: _fullNameController.text.trim(),
      dob: _dateToApiOrNull(_dobController.text) ?? '',
      cccd: identityNo.trim(),
      cccdIssueDate:
          _dateToApiOrNull(_identityIssueDateController.text) ?? '',
      identityIssuePlace: _textOrNull(_identityIssuePlaceController),
      identityType: _identityType,
      identityName: _textOrNull(_identityNameController),
      country: _textOrNull(_countryController),
      national: _textOrNull(_nationalController),
      hometown: _permanentAddressController.text.trim(),
      vneidPermanentAddress:
          _textOrNull(_vneidPermanentAddressController),
      permanentProvinceCode:
          _textOrNull(_permanentProvinceCodeController),
      permanentWardCode: _textOrNull(_permanentWardCodeController),
      contactAddress: _textOrNull(_contactAddressController),
      className: _classNameController.text.trim(),
      faculty: _textOrNull(_facultyController),
      major: _majorController.text.trim(),
      academicYear: _academicYearController.text.trim(),
      system: _systemController.text.trim(),
      level: _levelController.text.trim(),
      universityName: _universityController.text.trim(),
      priorityObjectName: _selectedPriorityObjectNames.isEmpty
          ? null
          : _selectedPriorityObjectNames,
      temporaryAddress: _temporaryAddressController.text.trim(),
      vneidTemporaryAddress:
          _textOrNull(_vneidTemporaryAddressController),
      temporaryProvinceCode:
          _textOrNull(_temporaryProvinceCodeController),
      temporaryWardCode: _textOrNull(_temporaryWardCodeController),
      reasonStay: _textOrNull(_reasonStayController),
      gender: _gender,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      familyMembers: _familyForms
          .map((_StudentFamilyMemberForm item) => item.toPayload())
          .toList(),
    );
  }

  Future<void> _loadPriorityObjects() async {
    if (_loadingPriorityObjects) return;

    setState(() {
      _loadingPriorityObjects = true;
      _priorityObjectsError = null;
    });

    try {
      final response = await _repository.getPriorityObjects();
      final List<PriorityObjectModel> items =
          response.data?.items ?? <PriorityObjectModel>[];

      final List<PriorityObjectModel> initiallySelected =
          items.where((PriorityObjectModel item) {
        final int? id = item.id;
        final String normalizedName = _normalizePriorityName(item.name);
        return (id != null && _initialPriorityObjectIds.contains(id)) ||
            (normalizedName.isNotEmpty &&
                _initialPriorityObjectNames.contains(normalizedName));
      }).toList();

      if (!mounted) return;
      setState(() {
        _priorityObjects
          ..clear()
          ..addAll(items);
        _selectedPriorityObjects
          ..clear()
          ..addAll(initiallySelected);
        _loadingPriorityObjects = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPriorityObjects = false;
        _priorityObjectsError =
            'Không tải được danh sách đối tượng ưu tiên.';
      });
      debugPrint('[DORMITORY-PRIORITY-LOAD-ERROR] $error');
    }
  }

  bool _isPriorityObjectSelected(PriorityObjectModel item) {
    return _selectedPriorityObjects.any((PriorityObjectModel selected) {
      if (item.id != null && selected.id != null) {
        return item.id == selected.id;
      }
      return _normalizePriorityName(item.name) ==
          _normalizePriorityName(selected.name);
    });
  }

  void _togglePriorityObject(PriorityObjectModel item) {
    final int index = _selectedPriorityObjects.indexWhere(
      (PriorityObjectModel selected) {
        if (item.id != null && selected.id != null) {
          return item.id == selected.id;
        }
        return _normalizePriorityName(item.name) ==
            _normalizePriorityName(selected.name);
      },
    );

    setState(() {
      if (index >= 0) {
        _selectedPriorityObjects.removeAt(index);
      } else {
        _selectedPriorityObjects.add(item);
      }
    });
  }

  String get _selectedPriorityObjectNames => _selectedPriorityObjects
      .map((PriorityObjectModel item) => (item.name ?? '').trim())
      .where((String name) => name.isNotEmpty)
      .join(', ');

  String _normalizePriorityName(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Không được để trống'
        : null;
  }

  String? _emailValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Không được để trống';
    final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailPattern.hasMatch(text) ? null : 'Email không hợp lệ';
  }

  String? _birthYearValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final int? year = int.tryParse(text);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      return 'Năm sinh không hợp lệ';
    }
    return null;
  }

  String? _textOrNull(TextEditingController controller) {
    final String text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String? _dateToApiOrNull(String value) {
    final String text = value.trim();
    if (text.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(text);
    return parsed?.toUtc().toIso8601String();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.colorError,
        content: Text(message),
      ),
    );
  }

  dynamic _readValue(
    dynamic source,
    List<String> keys,
    dynamic Function(dynamic object) getter,
  ) {
    if (source == null) return null;

    if (source is Map) {
      for (final String key in keys) {
        if (source.containsKey(key) && source[key] != null) {
          return source[key];
        }
      }
      return null;
    }

    try {
      return getter(source);
    } catch (_) {
      return null;
    }
  }

  String _readText(
    dynamic source,
    List<String> keys,
    dynamic Function(dynamic object) getter,
  ) {
    return _readValue(source, keys, getter)?.toString().trim() ?? '';
  }

  String _readDateText(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return DateFormat('yyyy-MM-dd').format(value);
    final DateTime? parsed = DateTime.tryParse(value.toString());
    return parsed == null ? '' : DateFormat('yyyy-MM-dd').format(parsed);
  }

  Set<int> _readExistingPriorityObjectIds() {
    final Set<int> result = <int>{};
    for (final dynamic source in <dynamic>[widget.student, widget.accommodation]) {
      _collectPriorityValues(source, result, null);
    }
    return result;
  }

  Set<String> _readExistingPriorityObjectNames() {
    final Set<String> result = <String>{};
    for (final dynamic source in <dynamic>[widget.student, widget.accommodation]) {
      _collectPriorityValues(source, null, result);
    }
    return result;
  }

  void _collectPriorityValues(
    dynamic source,
    Set<int>? ids,
    Set<String>? names,
  ) {
    if (source == null) return;

    final List<dynamic> rawValues = <dynamic>[
      _readValue(
        source,
        const <String>['priority_object_ids', 'priorityObjectIds'],
        (dynamic object) => object.priorityObjectIds,
      ),
      _readValue(
        source,
        const <String>['priority_objects', 'priorityObjects'],
        (dynamic object) => object.priorityObjects,
      ),
      _readValue(
        source,
        const <String>[
          'priority_object_name',
          'priorityObjectName',
          'priorityObject',
        ],
        (dynamic object) => object.priorityObjectName,
      ),
      _readValue(
        source,
        const <String>['registration', 'registration_detail'],
        (dynamic object) => object.registration,
      ),
    ];

    for (final dynamic raw in rawValues) {
      _collectSinglePriorityValue(raw, ids, names);
    }
  }

  void _collectSinglePriorityValue(
    dynamic raw,
    Set<int>? ids,
    Set<String>? names,
  ) {
    if (raw == null) return;

    if (raw is Iterable && raw is! String) {
      for (final dynamic item in raw) {
        _collectSinglePriorityValue(item, ids, names);
      }
      return;
    }

    if (raw is Map) {
      final dynamic idValue = raw['id'] ?? raw['priority_object_id'];
      final int? id = idValue is num
          ? idValue.toInt()
          : int.tryParse(idValue?.toString() ?? '');
      if (id != null) ids?.add(id);

      final String name = (raw['name'] ??
              raw['priority_object_name'] ??
              raw['priorityObjectName'])
          ?.toString()
          .trim() ?? '';
      final String normalizedName = _normalizePriorityName(name);
      if (normalizedName.isNotEmpty) names?.add(normalizedName);

      final dynamic nested = raw['priority_objects'] ??
          raw['priorityObjects'] ??
          raw['priority_object_ids'] ??
          raw['priorityObjectIds'];
      if (nested != null) {
        _collectSinglePriorityValue(nested, ids, names);
      }
      return;
    }

    if (raw is num) {
      ids?.add(raw.toInt());
      return;
    }

    final String text = raw.toString().trim();
    if (text.isEmpty) return;

    final int? numericId = int.tryParse(text);
    if (numericId != null) {
      ids?.add(numericId);
      return;
    }

    for (final String part in text.split(RegExp(r'[,;|]'))) {
      final String normalizedName = _normalizePriorityName(part);
      if (normalizedName.isNotEmpty) names?.add(normalizedName);
    }
  }

  List<_ExistingPriorityDocument> _readExistingPriorityDocuments(
    dynamic accommodation,
  ) {
    if (accommodation == null) return <_ExistingPriorityDocument>[];

    final List<dynamic> sources = <dynamic>[
      _readValue(
        accommodation,
        const <String>[
          'documents',
          'attachments',
          'attachment_files',
          'attachmentFiles',
        ],
        (dynamic object) => object.documents,
      ),
      _readValue(
        accommodation,
        const <String>['registration', 'registration_detail'],
        (dynamic object) => object.registration,
      ),
    ];

    final List<dynamic> rawDocuments = <dynamic>[];
    for (final dynamic source in sources) {
      if (source is Iterable) {
        rawDocuments.addAll(source);
      } else if (source is Map) {
        final dynamic nested = source['documents'] ??
            source['attachments'] ??
            source['attachment_files'] ??
            source['attachmentFiles'];
        if (nested is Iterable) rawDocuments.addAll(nested);
      } else if (source != null) {
        try {
          final dynamic nested = source.documents;
          if (nested is Iterable) rawDocuments.addAll(nested);
        } catch (_) {
          // Không có danh sách tài liệu lồng.
        }
      }
    }

    final List<_ExistingPriorityDocument> result =
        <_ExistingPriorityDocument>[];
    final Set<String> seen = <String>{};

    for (final dynamic item in rawDocuments) {
      final String name = _readText(
        item,
        const <String>[
          'name',
          'file_name',
          'fileName',
          'original_name',
          'originalName',
        ],
        (dynamic object) => object.name,
      );
      final String url = _readText(
        item,
        const <String>[
          'url',
          'file_url',
          'fileUrl',
          'path',
          'download_url',
          'downloadUrl',
        ],
        (dynamic object) => object.url,
      );
      final String type = _readText(
        item,
        const <String>[
          'type',
          'file_type',
          'fileType',
          'document_type',
          'documentType',
        ],
        (dynamic object) => object.type,
      );

      final String searchable = '$name $type'.toLowerCase();
      final bool isAvatar = searchable.contains('avatar') ||
          searchable.contains('ảnh thẻ') ||
          searchable.contains('anh the');
      final bool isIdentity = searchable.contains('cccd') ||
          searchable.contains('cmnd') ||
          searchable.contains('identity') ||
          searchable.contains('mặt trước') ||
          searchable.contains('mat truoc') ||
          searchable.contains('mặt sau') ||
          searchable.contains('mat sau');

      if (isAvatar || isIdentity) continue;
      if (name.isEmpty && url.isEmpty) continue;

      final String key = '${name.toLowerCase()}|${url.toLowerCase()}';
      if (!seen.add(key)) continue;

      result.add(
        _ExistingPriorityDocument(
          name: name.isEmpty ? 'Giấy tờ ưu tiên' : name,
          url: url,
        ),
      );
    }

    return result;
  }

  List<_StudentFamilyMemberForm> _readFamilyMembers(dynamic student) {
    final dynamic raw = _readValue(
      student,
      const <String>['family_members', 'familyMembers'],
      (dynamic object) => object.familyMembers,
    );

    if (raw is! Iterable) return <_StudentFamilyMemberForm>[];

    final List<_StudentFamilyMemberForm> result =
        <_StudentFamilyMemberForm>[];

    for (final dynamic item in raw) {
      if (item is FamilyMemberPayload) {
        result.add(_StudentFamilyMemberForm.fromPayload(item));
        continue;
      }

      if (item is Map) {
        result.add(
          _StudentFamilyMemberForm.fromPayload(
            FamilyMemberPayload.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
        continue;
      }

      final String relationship = _readText(
        item,
        const <String>['relationship'],
        (dynamic object) => object.relationship,
      );
      final String fullName = _readText(
        item,
        const <String>['full_name', 'fullName'],
        (dynamic object) => object.fullName,
      );
      final String birthYearText = _readText(
        item,
        const <String>['birth_year', 'birthYear'],
        (dynamic object) => object.birthYear,
      );
      final String occupation = _readText(
        item,
        const <String>['occupation'],
        (dynamic object) => object.occupation,
      );
      final String phone = _readText(
        item,
        const <String>['phone_number', 'phoneNumber'],
        (dynamic object) => object.phoneNumber,
      );

      if (fullName.isNotEmpty) {
        result.add(
          _StudentFamilyMemberForm.fromPayload(
            FamilyMemberPayload(
              relationship: relationship.isEmpty ? 'guardian' : relationship,
              fullName: fullName,
              birthYear: int.tryParse(birthYearText),
              occupation: occupation.isEmpty ? null : occupation,
              phoneNumber: phone.isEmpty ? null : phone,
            ),
          ),
        );
      }
    }

    return result;
  }
}

class _ExistingPriorityDocument {
  final String name;
  final String url;

  const _ExistingPriorityDocument({
    required this.name,
    required this.url,
  });
}

class _StudentFamilyMemberForm {
  String relationship;
  final TextEditingController fullNameController;
  final TextEditingController birthYearController;
  final TextEditingController occupationController;
  final TextEditingController phoneController;

  _StudentFamilyMemberForm({
    required this.relationship,
    required this.fullNameController,
    required this.birthYearController,
    required this.occupationController,
    required this.phoneController,
  });

  factory _StudentFamilyMemberForm.empty() {
    return _StudentFamilyMemberForm(
      relationship: 'father',
      fullNameController: TextEditingController(),
      birthYearController: TextEditingController(),
      occupationController: TextEditingController(),
      phoneController: TextEditingController(),
    );
  }

  factory _StudentFamilyMemberForm.fromPayload(FamilyMemberPayload payload) {
    return _StudentFamilyMemberForm(
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
