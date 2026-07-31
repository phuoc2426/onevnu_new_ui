import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';
import 'package:dio/dio.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'dormitory_registration_state.dart';

class DormitoryRegistrationCubit extends Cubit<DormitoryRegistrationState> {
  DormitoryRegistrationCubit() : super(DormitoryRegistrationInitial());

  final _repository = DormitoryRegistrationRepository();

  RegistrationPeriodModel? selectedPeriod;
  DormitoryModel? selectedDormitory;
  RoomTypeModel? selectedRoomType;
  /// Cho phép người dùng chọn đồng thời nhiều đối tượng ưu tiên.
  final List<PriorityObjectModel> selectedPriorityObjects =
      <PriorityObjectModel>[];

  /// Giữ tương thích với các màn hình/đoạn code cũ chỉ đọc một đối tượng.
  PriorityObjectModel? get selectedPriorityObject =>
      selectedPriorityObjects.isEmpty ? null : selectedPriorityObjects.first;

  set selectedPriorityObject(PriorityObjectModel? value) {
    selectedPriorityObjects.clear();
    if (value != null) {
      selectedPriorityObjects.add(value);
    }
  }

  bool isPriorityObjectSelected(PriorityObjectModel item) {
    return selectedPriorityObjects.any((PriorityObjectModel selected) {
      if (item.id != null && selected.id != null) {
        return item.id == selected.id;
      }

      return (item.name ?? '').trim() == (selected.name ?? '').trim();
    });
  }

  void togglePriorityObject(PriorityObjectModel item) {
    final int index = selectedPriorityObjects.indexWhere(
      (PriorityObjectModel selected) {
        if (item.id != null && selected.id != null) {
          return item.id == selected.id;
        }

        return (item.name ?? '').trim() == (selected.name ?? '').trim();
      },
    );

    if (index >= 0) {
      selectedPriorityObjects.removeAt(index);
    } else {
      selectedPriorityObjects.add(item);
    }
  }

  String get selectedPriorityObjectNames => selectedPriorityObjects
      .map((PriorityObjectModel item) => (item.name ?? '').trim())
      .where((String name) => name.isNotEmpty)
      .join(', ');
  List<UploadedAttachmentModel> uploadedAttachments = [];
  String? tempFullName;
  String? tempPhone;
  String? tempEmail;
  String? tempCccd;
  String? tempCccdIssueDate;
  String? tempHometown;
  String? tempTemporaryAddress;
  String? tempReason;
  String? tempDOB;
  String? tempGender;
  String? tempEthnicity;
  String? tempReligion;
  String? tempContactAddress;
  String? tempIdentityIssuePlace;
  String? tempFaculty;

  /// Ảnh thẻ được upload riêng qua API dùng chung với type=AVATAR.
  File? avatarFile;
  bool avatarUploaded = false;

  /// Danh sách bố/mẹ/người giám hộ của sinh viên.
  final List<FamilyMemberPayload> familyMembers = <FamilyMemberPayload>[];

  /// 1: Kỳ 1, 2: Kỳ 2, 3: Hè, 4: Giữa kỳ, 5: Khác.
  int selectedTermType = 1;

  /// Chỉ dùng khi [selectedTermType] = 5.
  DateTime? customStartDate;
  DateTime? customEndDate;

  List<RegistrationPeriodModel> periods = [];
  List<DormitoryModel> dormitories = [];
  List<RoomTypeModel> roomTypes = [];
  List<PriorityObjectModel> priorityObjects = [];

  /// Thông báo khi API không trả về ký túc xá khả dụng.
  String? dormitoryFilterMessage;

  bool hasAnyOpenRegistrationPeriod = false;
  bool isCheckingOpenRegistrationPeriod = false;
  int? firstOpenPeriodDormitoryId;
  String? openPeriodMessage;
  File? cccdFrontFile;
  File? cccdBackFile;

  UploadedAttachmentModel? cccdFrontAttachment;
  UploadedAttachmentModel? cccdBackAttachment;

  List<File> proofFiles = [];
  List<UploadedAttachmentModel> proofAttachments = [];
  static const Map<String, dynamic> _emptyMyRegistrationsData = {
    'student': null,
    'accommodations': [],
    'histories': [],
  };

  bool _isStudentRegistrationNotFound(Object error) {
    if (error is! DioException) return false;

    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final parts = <String>[
      error.toString(),
      error.message ?? '',
      error.error?.toString() ?? '',
    ];

    void collect(dynamic value) {
      if (value == null) return;
      if (value is Map) {
        value.forEach((key, item) {
          parts.add(key.toString());
          collect(item);
        });
        return;
      }
      if (value is Iterable) {
        for (final item in value) {
          collect(item);
        }
        return;
      }
      parts.add(value.toString());
    }

    collect(responseData);

    final text = parts.join(' ').toLowerCase();
    final mentionsIdentity =
        text.contains('student') ||
        text.contains('student_code') ||
        text.contains('mã sinh viên') ||
        text.contains('ma sinh vien') ||
        text.contains('sinh viên') ||
        text.contains('sinh vien') ||
        text.contains('cccd') ||
        text.contains('căn cước') ||
        text.contains('can cuoc') ||
        text.contains('căn cước công dân') ||
        text.contains('can cuoc cong dan') ||
        text.contains('citizen') ||
        text.contains('citizen_id') ||
        text.contains('identity') ||
        text.contains('identity_number');
    final mentionsNotFound =
        text.contains('not found') ||
        text.contains('không tồn tại') ||
        text.contains('khong ton tai') ||
        text.contains('không tìm thấy') ||
        text.contains('khong tim thay');

    return (statusCode == 404 && mentionsIdentity) ||
        (statusCode == 422 && mentionsIdentity && mentionsNotFound) ||
        (mentionsIdentity && mentionsNotFound);
  }

  Future<bool> checkAnyOpenRegistrationPeriod() async {
    isCheckingOpenRegistrationPeriod = true;
    hasAnyOpenRegistrationPeriod = false;
    firstOpenPeriodDormitoryId = null;
    openPeriodMessage = null;

    emit(DormitoryRegistrationOpenPeriodChecking());

    try {
      if (dormitories.isEmpty) {
        dormitories = await _loadAllDormitories();
      }

      if (dormitories.isEmpty) {
        openPeriodMessage =
            dormitoryFilterMessage ?? 'Không có ký túc xá khả dụng';
        emit(DormitoryRegistrationOpenPeriodChecked(false));
        return false;
      }

      for (final dormitory in dormitories) {
        final dormitoryId = dormitory.id;
        if (dormitoryId == null) continue;

        try {
          final periodRes = await _repository.getRegistrationPeriods(
            dormitoryId: dormitoryId,
          );

          final items = periodRes.data?.items ?? [];

          if (items.isNotEmpty) {
            hasAnyOpenRegistrationPeriod = true;
            firstOpenPeriodDormitoryId = dormitoryId;

            selectedDormitory = dormitory;
            periods = items;
            selectedPeriod = items.first;

            emit(DormitoryRegistrationOpenPeriodChecked(true));
            return true;
          }
        } catch (e) {
          logError(
            'Check registration period error for dormitory $dormitoryId: $e',
          );
        }
      }

      hasAnyOpenRegistrationPeriod = false;
      periods = [];
      selectedPeriod = null;
      openPeriodMessage = 'Hiện chưa có đợt đăng ký nội trú nào đang mở';

      emit(DormitoryRegistrationOpenPeriodChecked(false));
      return false;
    } catch (e) {
      logError(e.toString());

      hasAnyOpenRegistrationPeriod = false;
      openPeriodMessage = 'Không kiểm tra được đợt đăng ký nội trú';

      emit(DormitoryRegistrationOpenPeriodChecked(false));
      return false;
    } finally {
      isCheckingOpenRegistrationPeriod = false;
    }
  }

  DateTime _normalizeDateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String get selectedTermTypeLabel {
    switch (selectedTermType) {
      case 1:
        return 'Kỳ 1';
      case 2:
        return 'Kỳ 2';
      case 3:
        return 'Hè';
      case 4:
        return 'Giữa kỳ';
      case 5:
        return 'Khác';
      default:
        return 'Không xác định';
    }
  }

  void selectTermType(int value) {
    if (value < 1 || value > 5) {
      throw ArgumentError.value(value, 'value', 'term_type phải từ 1 đến 5');
    }

    selectedTermType = value;

    if (value != 5) {
      customStartDate = null;
      customEndDate = null;
      return;
    }

    // Khi chọn "Khác", tạo sẵn một khoảng hợp lệ để người dùng điều chỉnh.
    final DateTime today = _normalizeDateOnly(DateTime.now());
    customStartDate ??= today.add(const Duration(days: 1));
    customEndDate ??= customStartDate!.add(const Duration(days: 1));
  }

  void setCustomStartDate(DateTime value) {
    customStartDate = _normalizeDateOnly(value);

    if (customEndDate == null || !customEndDate!.isAfter(customStartDate!)) {
      customEndDate = customStartDate!.add(const Duration(days: 1));
    }
  }

  void setCustomEndDate(DateTime value) {
    customEndDate = _normalizeDateOnly(value);
  }

  String? validateStayPeriod() {
    if (selectedTermType < 1 || selectedTermType > 5) {
      return 'Vui lòng chọn kỳ ở ký túc xá';
    }

    if (selectedTermType != 5) {
      return null;
    }

    if (customStartDate == null) {
      return 'Vui lòng chọn ngày bắt đầu';
    }

    if (customEndDate == null) {
      return 'Vui lòng chọn ngày kết thúc';
    }

    final DateTime today = _normalizeDateOnly(DateTime.now());
    final DateTime start = _normalizeDateOnly(customStartDate!);
    final DateTime end = _normalizeDateOnly(customEndDate!);

    if (!start.isAfter(today)) {
      return 'Ngày bắt đầu phải lớn hơn ngày hiện tại';
    }

    if (!end.isAfter(start)) {
      return 'Ngày kết thúc phải lớn hơn ngày bắt đầu';
    }

    return null;
  }

  String _dateToApi(DateTime value) {
    // Dùng UTC 00:00 để ngày gửi lên không bị lệch do múi giờ thiết bị.
    return DateTime.utc(value.year, value.month, value.day).toIso8601String();
  }

  Future<RegistrationPayloadModel> buildRegistrationPayload({
    required String status,
    String? reason,
    List<Object> attachmentFileIds = const <Object>[],
  }) async {
    if (selectedPeriod?.id == null) {
      throw Exception('Không tìm thấy đợt đăng ký đang hoạt động');
    }

    if (selectedDormitory?.id == null) {
      throw Exception('Vui lòng chọn ký túc xá');
    }

    final String? stayPeriodError = validateStayPeriod();
    if (stayPeriodError != null) {
      throw Exception(stayPeriodError);
    }

    final RegistrationStudentPayload studentPayload =
        await _buildStudentPayload();

    final bool isCustomTerm = selectedTermType == 5;

    return RegistrationPayloadModel(
      registrationPeriodId: selectedPeriod!.id!,
      priorityObjectIds: selectedPriorityObjects
          .map((PriorityObjectModel item) => item.id)
          .whereType<int>()
          .toSet()
          .toList(),
      dormitoryId: selectedDormitory!.id!,
      // Sinh viên không chọn loại phòng.
      roomTypeId: null,
      status: status,
      reason: reason ?? tempReason ?? 'Đăng ký nội trú',
      termType: selectedTermType,
      startDate: isCustomTerm ? _dateToApi(customStartDate!) : null,
      endDate: isCustomTerm ? _dateToApi(customEndDate!) : null,
      attachmentFileIds: attachmentFileIds,
      student: studentPayload,
    );
  }

  void _emitEmptyMyRegistrations() {
    emit(DormitoryRegistrationMyRegistrationsLoaded(_emptyMyRegistrationsData));
  }

  Future<T?> _firstOrNull<T>(Future<List<T>> future) async {
    try {
      final data = await future;
      return data.isEmpty ? null : data.first;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<T?> _firstOrNullWhen<T>(
    String? key,
    Future<List<T>> Function() futureBuilder,
  ) {
    if (key == null || key.trim().isEmpty) {
      return Future.value(null);
    }
    return _firstOrNull(futureBuilder());
  }

  Future<T?> _nullable<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  String _dateOnly(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String().split('T').first;
    return value.toString().split('T').first;
  }

  String _joinAddress(List<Object?> parts) {
    final text = parts
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .join(', ');

    return text;
  }

  String _mapGender(String? value) {
    final text = value?.toLowerCase().trim() ?? '';

    if (text == 'female' || text == 'f' || text == 'nữ' || text == 'nu') {
      return 'female';
    }

    return 'male';
  }

  Future<void> _ensureStudentCache() async {
    // Nếu đã có thông tin sinh viên (Google login) thì không cần làm gì
    if (Globals().thongTinSinhVienModel.value != null) return;

    // Kiểm tra nếu là thí sinh (có cache applicant_cccd) thì không gọi API
    final prefs = await SharedPreferences.getInstance();
    final applicantCccd = prefs.getString('applicant_cccd');
    if (applicantCccd != null && applicantCccd.isNotEmpty) {
      // Không cần refresh student info từ server
      return;
    }

    if (Globals().thongTinSinhVienModel.value == null ||
        Globals().lopDaoTaoModel.value == null ||
        Globals().nienKhoaDaoTaoModel.value == null) {
      await Globals().refreshStudentInfo();
    }
  }

  Future<RegistrationStudentPayload> _buildStudentPayload() async {
    await _ensureStudentCache();

    final prefs = await SharedPreferences.getInstance();
    final repo = ApiRepository();
    final applicantCccd = prefs.getString('applicant_cccd');

    final student = Globals().thongTinSinhVienModel.value;
    final cachedClassInfo = Globals().lopDaoTaoModel.value;
    final cachedAcademicYear = Globals().nienKhoaDaoTaoModel.value;
    // ONEVNU_STALE_STUDENT_FIX_20260725_APPLICANT
    final String currentStudentCode = student?.maSinhVien?.trim() ?? '';
    final bool hasRegularStudent = currentStudentCode.isNotEmpty;
    final bool isApplicant =
        !hasRegularStudent &&
        applicantCccd != null &&
        applicantCccd.trim().isNotEmpty;
    if (isApplicant) {
      final fullName =
          tempFullName ?? prefs.getString('applicant_fullname') ?? '';
      final dob = tempDOB ?? prefs.getString('applicant_dob') ?? '';
      final phone =
          tempPhone ??
          prefs.getString('applicant_phone_number') ??
          // Fallback cho bản mobile cũ đã từng lưu sai key.
          prefs.getString('applicant_phone') ??
          '';
      final email = tempEmail ?? prefs.getString('applicant_email') ?? '';
      final cccd = tempCccd ?? applicantCccd ?? '';

      // Tên trường chỉ được gửi kèm nếu phiên Applicant đã có dữ liệu.
      // Không dùng trường để lọc KTX và không chặn đăng ký khi tên trường trống.
      final String universityName =
          prefs.getString('applicant_university_name')?.trim() ?? '';
      const int? univId = null;

      String dobFormatted = '';
      if (dob.isNotEmpty) {
        try {
          final parsed = DateTime.parse(dob);
          dobFormatted = parsed.toUtc().toIso8601String();
        } catch (_) {
          dobFormatted = dob; // fallback nếu không parse được
        }
      }
      return RegistrationStudentPayload(
        studentCode: '',
        fullName: fullName,
        dob: dobFormatted,
        cccd: cccd,
        cccdIssueDate: tempCccdIssueDate ?? '',
        hometown: tempHometown ?? '',
        className: '',
        major: '',
        academicYear: '',
        system: '',
        level: '',
        universityName: universityName,
        univId: univId,
        priorityObjectName: selectedPriorityObjectNames.isEmpty
            ? null
            : selectedPriorityObjectNames,
        temporaryAddress: tempTemporaryAddress ?? '',
        contactAddress: tempContactAddress,
        identityIssuePlace: tempIdentityIssuePlace,
        faculty: tempFaculty,
        gender: tempGender ?? 'male',
        ethnicity: tempEthnicity,
        religion: tempReligion,
        phone: phone,
        email: email,
        familyMembers: List<FamilyMemberPayload>.unmodifiable(familyMembers),
      );
    }
    if (student == null) {
      throw Exception('Thông tin sinh viên chính quy không tồn tại');
    }
    final guidDonVi = student.guidDonVi;

    final classInfo =
        cachedClassInfo ??
        await _firstOrNullWhen(
          student.idLopDaoTao,
          () => repo.getDataLopDaoTao(
            student.idLopDaoTao,
            guidDonVi,
            student.idBacDaoTao,
            student.idHeDaoTao,
            student.idNganhDaoTao,
            student.idNienKhoaDaoTao,
            student.idChuongTrinhDaoTao,
          ),
        );

    final major = await _firstOrNullWhen(
      student.idNganhDaoTao,
      () => repo.getDataNganhDaoTao(
        student.idNganhDaoTao,
        guidDonVi,
        student.idBacDaoTao,
      ),
    );

    final academicYear =
        cachedAcademicYear ??
        await _firstOrNullWhen(
          student.idNienKhoaDaoTao,
          () => repo.getDataNienKhoaDaoTao(
            student.idNienKhoaDaoTao,
            guidDonVi,
            student.idBacDaoTao,
          ),
        );

    final system = await _firstOrNullWhen(
      student.idHeDaoTao,
      () => repo.getDataHeDaoTao(
        student.idHeDaoTao,
        guidDonVi,
        student.idBacDaoTao,
      ),
    );

    final level = await _firstOrNullWhen(
      student.idBacDaoTao,
      () => repo.getDataBacDaoTao(student.idBacDaoTao, guidDonVi),
    );

    final priorityObject = await _firstOrNullWhen(
      student.idDoiTuongUuTien,
      () => repo.getDataDoiTuongUuTien(student.idDoiTuongUuTien, guidDonVi),
    );

    final university = guidDonVi == null || guidDonVi.trim().isEmpty
        ? null
        : await _nullable(() => repo.getDonVi(guidDonVi));

    final permanentProvince = await _firstOrNullWhen(
      student.idHoKhauThuongTruTinhThanhPho,
      () => repo.getDataTinhThanhPho(
        student.idHoKhauThuongTruTinhThanhPho,
        guidDonVi,
      ),
    );

    final permanentDistrict = await _firstOrNullWhen(
      student.idHoKhauThuongTruQuanHuyen,
      () => repo.getDataQuanHuyen(
        student.idHoKhauThuongTruQuanHuyen,
        guidDonVi,
        student.idHoKhauThuongTruTinhThanhPho,
      ),
    );

    final temporaryProvince = await _firstOrNullWhen(
      student.diaChiTamTruTinhThanhPho,
      () =>
          repo.getDataTinhThanhPho(student.diaChiTamTruTinhThanhPho, guidDonVi),
    );

    final temporaryDistrict = await _firstOrNullWhen(
      student.diaChiTamTruQuanHuyen,
      () => repo.getDataQuanHuyen(
        student.diaChiTamTruQuanHuyen,
        guidDonVi,
        student.diaChiTamTruTinhThanhPho,
      ),
    );

    final currentProvince = await _firstOrNullWhen(
      student.idNoiOHienNayTinhThanhPho,
      () => repo.getDataTinhThanhPho(
        student.idNoiOHienNayTinhThanhPho,
        guidDonVi,
      ),
    );

    final currentDistrict = await _firstOrNullWhen(
      student.idNoiOHienNayQuanHuyen,
      () => repo.getDataQuanHuyen(
        student.idNoiOHienNayQuanHuyen,
        guidDonVi,
        student.idNoiOHienNayTinhThanhPho,
      ),
    );

    final permanentAddress = _joinAddress([
      student.hoKhauThuongTruSoNha,
      student.hoKhauThuongTruDuongThon,
      student.hoKhauThuongTruPhuongXa,
      permanentDistrict?.ten ?? student.idHoKhauThuongTruQuanHuyen,
      permanentProvince?.ten ?? student.idHoKhauThuongTruTinhThanhPho,
    ]);

    final temporaryAddress = _joinAddress([
      student.diaChiTamTruSoNha,
      student.diaChiTamTruDuongThon,
      student.diaChiTamTruPhuongXa,
      temporaryDistrict?.ten ?? student.diaChiTamTruQuanHuyen,
      temporaryProvince?.ten ?? student.diaChiTamTruTinhThanhPho,
    ]);

    final currentAddress = _joinAddress([
      student.noiOHienNaySoNha,
      student.noiOHienNayDuongThon,
      student.noiOHienNayPhuongXa,
      currentDistrict?.ten ?? student.idNoiOHienNayQuanHuyen,
      currentProvince?.ten ?? student.idNoiOHienNayTinhThanhPho,
    ]);

    final contactAddress = _joinAddress([
      student.diaChiLienLacSoNha,
      student.diaChiLienLacDuongThon,
      student.diaChiLienLacPhuongXa,
    ]);

    return RegistrationStudentPayload(
      studentCode: student.maSinhVien ?? '',
      fullName: student.hoVaTen ?? '',
      dob: _dateOnly(student.ngaySinh),
      cccd: tempCccd ?? student.soCmtCccd ?? '',
      cccdIssueDate: tempCccdIssueDate ?? _dateOnly(student.ngayCapCmtCccd),
      hometown:
          tempHometown ??
          (permanentAddress.isNotEmpty
              ? permanentAddress
              : student.hoKhauThuongTruPhuongXa ?? ''),
      className:
          classInfo?.ten ?? classInfo?.tenVietTat ?? student.idLopDaoTao ?? '',
      major: major?.ten ?? student.idNganhDaoTao ?? '',
      academicYear:
          academicYear?.ten ??
          _joinAddress([academicYear?.namBatDau, academicYear?.namKetThuc]) ??
          student.idNienKhoaDaoTao ??
          '',
      system: system?.ten ?? student.idHeDaoTao ?? '',
      level: level?.ten ?? student.idBacDaoTao ?? '',
      universityName: university?.tenDonVi ?? '',
      univId: university?.idHeThongDaoTao,
      priorityObjectName: selectedPriorityObjectNames.isNotEmpty
          ? selectedPriorityObjectNames
          : priorityObject?.ten ?? '',
      temporaryAddress:
          tempTemporaryAddress ??
          (temporaryAddress.isNotEmpty
              ? temporaryAddress
              : currentAddress.isNotEmpty
              ? currentAddress
              : contactAddress),
      contactAddress: tempContactAddress ?? contactAddress,
      identityIssuePlace: tempIdentityIssuePlace,
      faculty: tempFaculty,
      gender: tempGender ?? _mapGender(student.gioiTinh),
      ethnicity: tempEthnicity,
      religion: tempReligion,
      phone: tempPhone ?? student.mobile ?? student.tel ?? '',
      email: tempEmail ?? student.email ?? student.emailKhac ?? '',
      familyMembers: List<FamilyMemberPayload>.unmodifiable(familyMembers),
    );
  }

  String _uploadErrorMessage(Object error) {
    if (error is DioException) {
      final dynamic responseData = error.response?.data;

      if (responseData is Map) {
        final dynamic rawErrors = responseData['errors'];
        if (rawErrors is Map && rawErrors.isNotEmpty) {
          final List<String> messages = <String>[];
          rawErrors.forEach((dynamic key, dynamic value) {
            if (value is Iterable) {
              for (final dynamic item in value) {
                final String text = item?.toString().trim() ?? '';
                if (text.isNotEmpty) messages.add(text);
              }
            } else {
              final String text = value?.toString().trim() ?? '';
              if (text.isNotEmpty) messages.add(text);
            }
          });

          if (messages.isNotEmpty) {
            return messages.toSet().join('\n');
          }
        }

        final String message =
            responseData['message']?.toString().trim() ?? '';
        if (message.isNotEmpty) return message;
      }

      final String dioMessage = error.message?.trim() ?? '';
      if (dioMessage.isNotEmpty) return dioMessage;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  void clearWizardData() {
    selectedPeriod = null;
    selectedDormitory = null;
    selectedRoomType = null;
    selectedPriorityObjects.clear();
    uploadedAttachments.clear();
    cccdFrontAttachment = null;
    cccdBackAttachment = null;
    proofAttachments.clear();
    cccdFrontFile = null;
    cccdBackFile = null;
    proofFiles.clear();
    tempFullName = null;
    tempDOB = null;
    selectedTermType = 1;
    customStartDate = null;
    customEndDate = null;
    tempPhone = null;
    tempEmail = null;
    tempCccd = null;
    tempCccdIssueDate = null;
    tempHometown = null;
    tempTemporaryAddress = null;
    tempReason = null;
    tempGender = null;
    tempEthnicity = null;
    tempReligion = null;
    tempContactAddress = null;
    tempIdentityIssuePlace = null;
    tempFaculty = null;
    avatarFile = null;
    avatarUploaded = false;
    familyMembers.clear();
  }

  /// Lấy đợt đăng ký active mới nhất của KTX và tự động chọn đợt đó.
  ///
  /// API: GET /api/dormitory/{dormitory}/registration-periods
  /// Người dùng không còn phải chọn đợt trên giao diện.
  Future<RegistrationPeriodModel?> getRegistrationPeriods({
    int? dormitoryId,
  }) async {
    emit(DormitoryRegistrationLoading());

    try {
      final selectedDormitoryId = dormitoryId ?? selectedDormitory?.id;

      if (selectedDormitoryId == null) {
        periods = [];
        selectedPeriod = null;
        emit(DormitoryRegistrationPeriodsLoaded(periods));
        return null;
      }

      final res = await _repository.getRegistrationPeriods(
        dormitoryId: selectedDormitoryId,
      );

      // API trả về đợt active mới nhất của KTX hoặc null.
      periods = res.data?.items ?? [];
      selectedPeriod = periods.isNotEmpty ? periods.first : null;

      emit(DormitoryRegistrationPeriodsLoaded(periods));
      return selectedPeriod;
    } catch (e) {
      periods = [];
      selectedPeriod = null;
      logError('Get active registration period error: $e');
      emit(DormitoryRegistrationError(e.toString()));
      return null;
    }
  }

  Future<void> getDormitories() async {
    emit(DormitoryRegistrationLoading());
    try {
      dormitories = await _loadAllDormitories();

      if (selectedDormitory != null &&
          !dormitories.any(
            (DormitoryModel item) => item.id == selectedDormitory?.id,
          )) {
        selectedDormitory = null;
        selectedPeriod = null;
        periods = <RegistrationPeriodModel>[];
      }

      emit(DormitoryRegistrationDormitoriesLoaded(dormitories));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  /// Lấy toàn bộ ký túc xá từ API.
  ///
  /// Không lọc theo trường/đơn vị đào tạo. Mọi tài khoản đều được phép
  /// xem và lựa chọn tất cả ký túc xá mà API trả về.
  Future<List<DormitoryModel>> _loadAllDormitories() async {
    final res = await _repository.getDormitories();
    final List<DormitoryModel> allDormitories =
        res.data?.items ?? const <DormitoryModel>[];

    dormitoryFilterMessage = allDormitories.isEmpty
        ? 'Hiện chưa có ký túc xá khả dụng.'
        : null;

    logInfo(
      '[DORMITORY_ALL] total=${allDormitories.length}',
    );

    return allDormitories;
  }

  Future<void> getRoomTypes() async {
    emit(DormitoryRegistrationLoading());
    try {
      final res = await _repository.getRoomTypes();
      roomTypes = res.data?.items ?? [];
      emit(DormitoryRegistrationRoomTypesLoaded(roomTypes));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> getPriorityObjects() async {
    emit(DormitoryRegistrationLoading());
    try {
      final res = await _repository.getPriorityObjects();
      priorityObjects = res.data?.items ?? [];
      emit(DormitoryRegistrationPriorityObjectsLoaded(priorityObjects));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> getMyRegistrations({
    String? studentCode,
    String? identityNo,
  }) async {
    try {
      final code =
          studentCode ??
          Globals().thongTinSinhVienModel.value?.maSinhVien ??
          '';
      final effectiveIdentityNo =
          identityNo ??
          (code.isEmpty
              ? (await SharedPreferences.getInstance()).getString(
                  'applicant_cccd',
                )
              : null);
      if (code.isEmpty &&
          (effectiveIdentityNo == null || effectiveIdentityNo.isEmpty)) {
        emit(DormitoryRegistrationDismissHub());
        _emitEmptyMyRegistrations();
        return;
      }

      final res = await _repository.getMyRegistrations(
        studentCode: code.isNotEmpty ? code : null,
        identityNo: effectiveIdentityNo,
      );
      emit(DormitoryRegistrationDismissHub());

      emit(
        DormitoryRegistrationMyRegistrationsLoaded(
          res.data ?? _emptyMyRegistrationsData,
        ),
      );
    } catch (e) {
      emit(DormitoryRegistrationDismissHub());

      if (_isStudentRegistrationNotFound(e)) {
        _emitEmptyMyRegistrations();
        return;
      }

      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 500) {
          _emitEmptyMyRegistrations();
          return;
        }

        final message = responseData is Map
            ? responseData['message']?.toString().toLowerCase() ?? ''
            : e.message?.toLowerCase() ?? '';

        final isStudentNotFound =
            statusCode == 404 ||
            message.contains('student') ||
            message.contains('not found') ||
            message.contains('không tồn tại') ||
            message.contains('khong ton tai') ||
            message.contains('không tìm thấy') ||
            message.contains('khong tim thay');

        if (isStudentNotFound) {
          emit(
            DormitoryRegistrationMyRegistrationsLoaded({
              'student': null,
              'accommodations': [],
              'histories': [],
            }),
          );
          return;
        }
      }

      logError(e.toString());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> getRegistrationDetail(Object id) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      final res = await _repository.getRegistrationDetail(id);
      emit(DormitoryRegistrationDismissHub());
      if (res.data != null) {
        emit(DormitoryRegistrationDetailLoaded(res.data!));
      } else {
        emit(DormitoryRegistrationError('Không tìm thấy chi tiết đơn đăng ký'));
      }
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> getRegistrationHistories(Object id) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      final res = await _repository.getRegistrationHistories(id);
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationHistoryLoaded(res.data ?? []));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> uploadCCCDFront(File file) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      final studentPayload = await _buildStudentPayload();
      final res = await _repository.uploadAttachment(
        student: studentPayload,
        files: [file],
      );
      emit(DormitoryRegistrationDismissHub());
      if (res.data != null && res.data!.isNotEmpty) {
        cccdFrontAttachment = res.data!.first;
        emit(DormitoryRegistrationUploadSuccess(res.data!.first));
      } else {
        emit(
          DormitoryRegistrationUploadError(
            'Không nhận được thông tin file sau khi upload',
          ),
        );
      }
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationUploadError(_uploadErrorMessage(e)));
    }
  }

  Future<void> uploadCCCDBack(File file) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      final studentPayload = await _buildStudentPayload();
      final res = await _repository.uploadAttachment(
        student: studentPayload,
        files: [file],
      );
      emit(DormitoryRegistrationDismissHub());
      if (res.data != null && res.data!.isNotEmpty) {
        cccdBackAttachment = res.data!.first;
        emit(DormitoryRegistrationUploadSuccess(res.data!.first));
      } else {
        emit(
          DormitoryRegistrationUploadError(
            'Không nhận được thông tin file sau khi upload',
          ),
        );
      }
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationUploadError(_uploadErrorMessage(e)));
    }
  }

  Future<void> uploadProofFile(File file) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      final studentPayload = await _buildStudentPayload();
      final res = await _repository.uploadAttachment(
        student: studentPayload,
        files: [file],
      );
      emit(DormitoryRegistrationDismissHub());
      if (res.data != null && res.data!.isNotEmpty) {
        proofAttachments.add(res.data!.first);
        emit(DormitoryRegistrationUploadSuccess(res.data!.first));
      } else {
        emit(
          DormitoryRegistrationUploadError(
            'Không nhận được thông tin file sau khi upload',
          ),
        );
      }
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationUploadError(_uploadErrorMessage(e)));
    }
  }

  Future<void> submitRegistration(RegistrationPayloadModel payload) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      final uploadSuccess = await uploadCachedFiles();
      if (!uploadSuccess) {
        emit(DormitoryRegistrationDismissHub());
        emit(DormitoryRegistrationError('Upload file thất bại'));
        return;
      }

      final attachmentIds = <Object>[];
      if (cccdFrontAttachment?.id != null)
        attachmentIds.add(cccdFrontAttachment!.id!);
      if (cccdBackAttachment?.id != null)
        attachmentIds.add(cccdBackAttachment!.id!);
      attachmentIds.addAll(
        proofAttachments.where((e) => e.id != null).map((e) => e.id!),
      );

      final finalPayload = payload.copyWith(attachmentFileIds: attachmentIds);
      debugPrint('=== PAYLOAD GỬI ĐI ===');
      debugPrint(
        'Payload fields: ${finalPayload.toJson()}',
      ); // nếu RegistrationPayloadModel có toJson()
      debugPrint('Attachment IDs: $attachmentIds');
      await _repository.registerDormitory(finalPayload);

      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationSavedSuccess('Đăng ký nội trú thành công!'));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  void selectAvatar(File file) {
    avatarFile = file;
    avatarUploaded = false;
    emit(DormitoryRegistrationFileSelected('avatar', file));
  }

  void removeAvatar() {
    avatarFile = null;
    avatarUploaded = false;
    emit(DormitoryRegistrationFileChanged('avatar_removed'));
  }

  void replaceFamilyMembers(List<FamilyMemberPayload> values) {
    familyMembers
      ..clear()
      ..addAll(values);
    emit(DormitoryRegistrationFileChanged('family_members_changed'));
  }

  void selectCCCDFront(File file) {
    cccdFrontFile = file;

    // Nếu người dùng chọn lại ảnh mới, attachment cũ không còn đại diện cho ảnh hiện tại nữa.
    cccdFrontAttachment = null;

    emit(DormitoryRegistrationFileSelected('cccd_front', file));
  }

  void selectCCCDBack(File file) {
    cccdBackFile = file;

    // Nếu người dùng chọn lại ảnh mới, attachment cũ không còn đại diện cho ảnh hiện tại nữa.
    cccdBackAttachment = null;

    emit(DormitoryRegistrationFileSelected('cccd_back', file));
  }

  void addProofFile(File file) {
    proofFiles.add(file);
    emit(DormitoryRegistrationFileSelected('proof', file));
  }

  void removeCCCDFront() {
    cccdFrontFile = null;
    cccdFrontAttachment = null;

    emit(DormitoryRegistrationFileChanged('cccd_front_removed'));
  }

  void removeCCCDBack() {
    cccdBackFile = null;
    cccdBackAttachment = null;

    emit(DormitoryRegistrationFileChanged('cccd_back_removed'));
  }

  void removeProofFileAt(int index) {
    if (index < 0 || index >= proofFiles.length) {
      return;
    }

    proofFiles.removeAt(index);

    emit(DormitoryRegistrationFileChanged('proof_removed'));
  }

  void removeProofAttachmentAt(int index) {
    if (index < 0 || index >= proofAttachments.length) {
      return;
    }

    proofAttachments.removeAt(index);

    emit(DormitoryRegistrationFileChanged('proof_attachment_removed'));
  }

  void clearProofFiles() {
    proofFiles.clear();

    emit(DormitoryRegistrationFileChanged('proof_cleared'));
  }

  void clearAllSelectedFiles() {
    avatarFile = null;
    avatarUploaded = false;
    cccdFrontFile = null;
    cccdBackFile = null;
    cccdFrontAttachment = null;
    cccdBackAttachment = null;
    proofFiles.clear();
    proofAttachments.clear();

    emit(DormitoryRegistrationFileChanged('all_files_cleared'));
  }

  Future<bool> uploadCachedFiles() async {
    int totalSteps = 0;
    if (avatarFile != null && !avatarUploaded) totalSteps++;
    if (cccdFrontFile != null) totalSteps++;
    if (cccdBackFile != null) totalSteps++;
    if (proofFiles.isNotEmpty) totalSteps++;

    try {
      final RegistrationStudentPayload studentPayload =
          await _buildStudentPayload();
      int currentStep = 0;

      // 1. Upload ảnh thẻ bằng API dùng chung:
      // type=AVATAR và files[]. Không gửi avatar trong request đăng ký.
      if (avatarFile != null && !avatarUploaded) {
        emit(
          DormitoryRegistrationUploadProgress(
            totalSteps == 0 ? 0 : currentStep / totalSteps,
            'Đang tải lên ảnh thẻ sinh viên...',
          ),
        );

        final UploadedAttachmentListResponse response =
            await _repository.uploadAvatar(
          student: studentPayload,
          file: avatarFile!,
        );

        if (response.success != true &&
            (response.data == null || response.data!.isEmpty)) {
          throw Exception('Không tải được ảnh thẻ sinh viên');
        }

        avatarUploaded = true;
        currentStep++;

        emit(
          DormitoryRegistrationUploadProgress(
            totalSteps == 0 ? 1 : currentStep / totalSteps,
            'Đã tải lên ảnh thẻ sinh viên',
          ),
        );
      }

      // 2. Upload CCCD mặt trước
      if (cccdFrontFile != null) {
        emit(
          DormitoryRegistrationUploadProgress(
            currentStep / totalSteps,
            "Đang tải lên CCCD mặt trước (${(currentStep / totalSteps * 100).toInt()}%)...",
          ),
        );
        final res = await _repository.uploadAttachment(
          student: studentPayload,
          files: [cccdFrontFile!],
        );
        if (res.data != null && res.data!.isNotEmpty) {
          cccdFrontAttachment = res.data!.first;
          cccdFrontFile = null;
          currentStep++;
          emit(
            DormitoryRegistrationUploadProgress(
              currentStep / totalSteps,
              "Đang tải lên CCCD mặt trước (${(currentStep / totalSteps * 100).toInt()}%)...",
            ),
          );
        } else {
          throw Exception(
            'Không nhận được thông tin file sau khi upload CCCD mặt trước',
          );
        }
      }

      // 3. Upload CCCD mặt sau
      if (cccdBackFile != null) {
        emit(
          DormitoryRegistrationUploadProgress(
            currentStep / totalSteps,
            "Đang tải lên CCCD mặt sau (${(currentStep / totalSteps * 100).toInt()}%)...",
          ),
        );
        final res = await _repository.uploadAttachment(
          student: studentPayload,
          files: [cccdBackFile!],
        );
        if (res.data != null && res.data!.isNotEmpty) {
          cccdBackAttachment = res.data!.first;
          cccdBackFile = null;
          currentStep++;
          emit(
            DormitoryRegistrationUploadProgress(
              currentStep / totalSteps,
              "Đang tải lên CCCD mặt sau (${(currentStep / totalSteps * 100).toInt()}%)...",
            ),
          );
        } else {
          throw Exception(
            'Không nhận được thông tin file sau khi upload CCCD mặt sau',
          );
        }
      }

      // 4. Upload từng giấy tờ ưu tiên, không gom nhiều ảnh vào một request
      if (proofFiles.isNotEmpty) {
        final filesToUpload = List<File>.from(proofFiles);

        for (int i = 0; i < filesToUpload.length; i++) {
          final file = filesToUpload[i];

          emit(
            DormitoryRegistrationUploadProgress(
              currentStep / totalSteps,
              "Đang tải lên tài liệu minh chứng ${i + 1}/${filesToUpload.length}...",
            ),
          );

          final res = await _repository.uploadAttachment(
            student: studentPayload,
            files: [file],
          );

          if (res.data != null && res.data!.isNotEmpty) {
            proofAttachments.addAll(res.data!);
          } else {
            throw Exception(
              'Không nhận được thông tin file sau khi upload tài liệu ưu tiên ${i + 1}',
            );
          }
        }

        proofFiles.clear();
        currentStep++;

        emit(
          DormitoryRegistrationUploadProgress(
            currentStep / totalSteps,
            "Đã tải lên tài liệu minh chứng (${(currentStep / totalSteps * 100).toInt()}%)...",
          ),
        );
      }
      emit(
        DormitoryRegistrationUploadProgress(1.0, "Đang hoàn tất đăng ký..."),
      );
      emit(DormitoryRegistrationDismissHub());
      return true;
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationUploadError(_uploadErrorMessage(e)));
      return false;
    }
  }
}
