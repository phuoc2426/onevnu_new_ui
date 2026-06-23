import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';
import 'package:dio/dio.dart';
import 'package:vnu_core/repository/app_repository.dart';
part 'dormitory_registration_state.dart';

class DormitoryRegistrationCubit extends Cubit<DormitoryRegistrationState> {
  DormitoryRegistrationCubit() : super(DormitoryRegistrationInitial());

  final _repository = DormitoryRegistrationRepository();

  MyRegistrationModel? draftRecord;
  RegistrationPeriodModel? selectedPeriod;
  DormitoryModel? selectedDormitory;
  RoomTypeModel? selectedRoomType;
  PriorityObjectModel? selectedPriorityObject;
  List<UploadedAttachmentModel> uploadedAttachments = [];
  String? tempPhone;
  String? tempEmail;
  String? tempCccd;
  String? tempCccdIssueDate;
  String? tempHometown;
  String? tempTemporaryAddress;
  String? tempReason;

  List<RegistrationPeriodModel> periods = [];
  List<DormitoryModel> dormitories = [];
  List<RoomTypeModel> roomTypes = [];
  List<PriorityObjectModel> priorityObjects = [];

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
    final mentionsStudent =
        text.contains('student') ||
        text.contains('student_code') ||
        text.contains('mã sinh viên') ||
        text.contains('ma sinh vien') ||
        text.contains('sinh viên') ||
        text.contains('sinh vien');
    final mentionsNotFound =
        text.contains('not found') ||
        text.contains('không tồn tại') ||
        text.contains('khong ton tai') ||
        text.contains('không tìm thấy') ||
        text.contains('khong tim thay');

    return (statusCode == 404 && mentionsStudent) ||
        (statusCode == 422 && mentionsStudent && mentionsNotFound) ||
        (mentionsStudent && mentionsNotFound);
  }

  Future<bool> checkAnyOpenRegistrationPeriod() async {
    isCheckingOpenRegistrationPeriod = true;
    hasAnyOpenRegistrationPeriod = false;
    firstOpenPeriodDormitoryId = null;
    openPeriodMessage = null;

    emit(DormitoryRegistrationOpenPeriodChecking());

    try {
      if (dormitories.isEmpty) {
        final dormitoryRes = await _repository.getDormitories();
        dormitories = dormitoryRes.data?.items ?? [];
      }

      if (dormitories.isEmpty) {
        openPeriodMessage = 'Không có ký túc xá khả dụng';
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
          logError('Check registration period error for dormitory $dormitoryId: $e');
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

  Future<RegistrationPayloadModel> buildRegistrationPayload({
    required String status,
    String? reason,
    List<Object> attachmentFileIds = const [],
  }) async {
    if (selectedPeriod?.id == null) {
      throw Exception('Vui lòng chọn đợt đăng ký');
    }

    if (selectedDormitory?.id == null) {
      throw Exception('Vui lòng chọn ký túc xá');
    }

    if (selectedRoomType?.id == null) {
      throw Exception('Vui lòng chọn loại phòng');
    }

    final studentPayload = await _buildStudentPayload();

    return RegistrationPayloadModel(
      registrationPeriodId: selectedPeriod!.id!,
      priorityObjectIds: [
        if (selectedPriorityObject?.id != null) selectedPriorityObject!.id!,
      ],
      dormitoryId: selectedDormitory!.id!,
      roomTypeId: selectedRoomType!.id!,
      status: status,
      reason: reason ?? tempReason ?? 'Đăng ký nội trú',
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
    if (Globals().thongTinSinhVienModel.value == null ||
        Globals().lopDaoTaoModel.value == null ||
        Globals().nienKhoaDaoTaoModel.value == null) {
      await Globals().refreshStudentInfo();
    }
  }
  Future<RegistrationStudentPayload> _buildStudentPayload() async {
    await _ensureStudentCache();

    final repo = ApiRepository();

    final student = Globals().thongTinSinhVienModel.value;
    final cachedClassInfo = Globals().lopDaoTaoModel.value;
    final cachedAcademicYear = Globals().nienKhoaDaoTaoModel.value;

    if (student == null) {
      return RegistrationStudentPayload(
        studentCode: '',
        fullName: '',
        dob: '',
        cccd: tempCccd ?? '',
        cccdIssueDate: tempCccdIssueDate ?? '',
        hometown: tempHometown ?? '',
        className: '',
        major: '',
        academicYear: '',
        system: '',
        level: '',
        universityName: '',
        univId: null,
        priorityObjectName: selectedPriorityObject?.name,
        temporaryAddress: tempTemporaryAddress ?? '',
        gender: 'male',
        phone: tempPhone ?? '',
        email: tempEmail ?? '',
      );
    }

    final guidDonVi = student.guidDonVi;

    final classInfo = cachedClassInfo ??
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

    final academicYear = cachedAcademicYear ??
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
          () => repo.getDataBacDaoTao(
        student.idBacDaoTao,
        guidDonVi,
      ),
    );

    final priorityObject = await _firstOrNullWhen(
      student.idDoiTuongUuTien,
          () => repo.getDataDoiTuongUuTien(
        student.idDoiTuongUuTien,
        guidDonVi,
      ),
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
          () => repo.getDataTinhThanhPho(
        student.diaChiTamTruTinhThanhPho,
        guidDonVi,
      ),
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
      hometown: tempHometown ??
          (permanentAddress.isNotEmpty
              ? permanentAddress
              : student.hoKhauThuongTruPhuongXa ?? ''),
      className: classInfo?.ten ?? classInfo?.tenVietTat ?? student.idLopDaoTao ?? '',
      major: major?.ten ?? student.idNganhDaoTao ?? '',
      academicYear: academicYear?.ten ??
          _joinAddress([
            academicYear?.namBatDau,
            academicYear?.namKetThuc,
          ]) ??
          student.idNienKhoaDaoTao ??
          '',
      system: system?.ten ?? student.idHeDaoTao ?? '',
      level: level?.ten ?? student.idBacDaoTao ?? '',
      universityName: university?.tenDonVi ?? '',
      univId: university?.idHeThongDaoTao,
      priorityObjectName:
      selectedPriorityObject?.name ?? priorityObject?.ten ?? '',
      temporaryAddress: tempTemporaryAddress ??
          (temporaryAddress.isNotEmpty
              ? temporaryAddress
              : currentAddress.isNotEmpty
              ? currentAddress
              : contactAddress),
      gender: _mapGender(student.gioiTinh),
      phone: tempPhone ?? student.mobile ?? student.tel ?? '',
      email: tempEmail ?? student.email ?? student.emailKhac ?? '',
    );
  }

  void clearWizardData() {
    draftRecord = null;
    selectedPeriod = null;
    selectedDormitory = null;
    selectedRoomType = null;
    selectedPriorityObject = null;
    uploadedAttachments.clear();
    cccdFrontAttachment = null;
    cccdBackAttachment = null;
    proofAttachments.clear();
    cccdFrontFile = null;
    cccdBackFile = null;
    proofFiles.clear();
    tempPhone = null;
    tempEmail = null;
    tempCccd = null;
    tempCccdIssueDate = null;
    tempHometown = null;
    tempTemporaryAddress = null;
    tempReason = null;
  }

  void loadDraftData(MyRegistrationModel draft) {
    draftRecord = draft;
    if (periods.isNotEmpty) {
      selectedPeriod = periods.firstWhere(
        (p) => p.id == draft.registrationPeriodId,
        orElse: () => periods.first,
      );
    }
    if (dormitories.isNotEmpty) {
      selectedDormitory = dormitories.firstWhere(
        (d) => d.id == draft.dormitoryId,
        orElse: () => dormitories.first,
      );
    }
    if (roomTypes.isNotEmpty) {
      selectedRoomType = roomTypes.firstWhere(
        (r) => r.id == draft.roomTypeId,
        orElse: () => roomTypes.first,
      );
    }
    if (priorityObjects.isNotEmpty) {
      final matching = priorityObjects.where(
        (p) => p.id == draft.priorityObjectId,
      );
      selectedPriorityObject = matching.isNotEmpty ? matching.first : null;
    }
    tempReason = draft.note;

    // Load student info from draft
    if (draft.student != null) {
      tempPhone = draft.student!.phone;
      tempEmail = draft.student!.email;
      tempCccd = draft.student!.cccd;
      tempCccdIssueDate = draft.student!.cccdIssueDate;
      tempHometown = draft.student!.hometown;
      tempTemporaryAddress = draft.student!.temporaryAddress;
    }

    // Load documents from draft
    if (draft.documents != null) {
      for (final doc in draft.documents!) {
        final type = doc.type?.toLowerCase();
        if (type == 'cccd_front') {
          cccdFrontAttachment = doc;
        } else if (type == 'cccd_back') {
          cccdBackAttachment = doc;
        } else if (type == 'proof') {
          if (!proofAttachments.any((e) => e.id == doc.id)) {
            proofAttachments.add(doc);
          }
        }
      }
    }
  }

  Future<void> getRegistrationPeriods({int? dormitoryId}) async {
    emit(DormitoryRegistrationLoading());
    try {
      final selectedDormitoryId = dormitoryId ?? selectedDormitory?.id;
      if (selectedDormitoryId == null) {
        periods = [];
        selectedPeriod = null;
        emit(DormitoryRegistrationPeriodsLoaded(periods));
        return;
      }

      final res = await _repository.getRegistrationPeriods(
        dormitoryId: selectedDormitoryId,
      );
      periods = res.data?.items ?? [];
      if (selectedPeriod != null &&
          !periods.any((p) => p.id == selectedPeriod!.id)) {
        selectedPeriod = null;
      }
      if (draftRecord != null && periods.isNotEmpty) {
        selectedPeriod = periods.firstWhere(
          (p) => p.id == draftRecord!.registrationPeriodId,
          orElse: () => periods.first,
        );
      }
      emit(DormitoryRegistrationPeriodsLoaded(periods));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> getDormitories() async {
    emit(DormitoryRegistrationLoading());
    try {
      final res = await _repository.getDormitories();
      dormitories = res.data?.items ?? [];
      if (draftRecord != null && dormitories.isNotEmpty) {
        selectedDormitory = dormitories.firstWhere(
          (d) => d.id == draftRecord!.dormitoryId,
          orElse: () => dormitories.first,
        );
      }
      emit(DormitoryRegistrationDormitoriesLoaded(dormitories));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> getRoomTypes() async {
    emit(DormitoryRegistrationLoading());
    try {
      final res = await _repository.getRoomTypes();
      roomTypes = res.data?.items ?? [];
      if (draftRecord != null && roomTypes.isNotEmpty) {
        selectedRoomType = roomTypes.firstWhere(
          (r) => r.id == draftRecord!.roomTypeId,
          orElse: () => roomTypes.first,
        );
      }
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
      if (draftRecord != null && priorityObjects.isNotEmpty) {
        final matching = priorityObjects.where(
          (p) => p.id == draftRecord!.priorityObjectId,
        );
        selectedPriorityObject = matching.isNotEmpty ? matching.first : null;
      }
      emit(DormitoryRegistrationPriorityObjectsLoaded(priorityObjects));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> getMyRegistrations({String? studentCode}) async {
    try {
      final code =
          studentCode ??
          Globals().thongTinSinhVienModel.value?.maSinhVien ??
          '';

      if (code.isEmpty) {
        emit(DormitoryRegistrationDismissHub());
        _emitEmptyMyRegistrations();
        return;
      }

      final res = await _repository.getMyRegistrations(studentCode: code);

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
      emit(DormitoryRegistrationUploadError(e.toString()));
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
      emit(DormitoryRegistrationUploadError(e.toString()));
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
      emit(DormitoryRegistrationUploadError(e.toString()));
    }
  }

  Future<void> submitDraft(Object id) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      await _repository.submitDraft(id);
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationSavedSuccess('Gửi đăng ký thành công!'));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationError(e.toString()));
    }
  }

  Future<void> registerDormitory(RegistrationPayloadModel payload) async {
    // emit(DormitoryRegistrationShowHub());
    try {
      final res = await _repository.registerDormitory(payload);
      if (res.data != null) {
        draftRecord = res.data;
      }
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationSavedSuccess('Đăng ký nội trú thành công!'));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationError(e.toString()));
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

      final res = await _repository.registerDormitory(finalPayload);
      if (res.data != null) {
        draftRecord = res.data;
      }

      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationSavedSuccess('Đăng ký nội trú thành công!'));
    } catch (e) {
      logError(e.toString());
      emit(DormitoryRegistrationDismissHub());
      emit(DormitoryRegistrationError(e.toString()));
    }
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
    if (cccdFrontFile != null) totalSteps++;
    if (cccdBackFile != null) totalSteps++;
    if (proofFiles.isNotEmpty) totalSteps++;

    // emit(DormitoryRegistrationShowHub());
    if (totalSteps == 0) {
      // emit(DormitoryRegistrationUploadProgress(1.0, "Đang xử lý hồ sơ..."));
    }

    try {
      final studentPayload = await _buildStudentPayload();
      int currentStep = 0;

      // 1. Upload CCCD mặt trước
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

      // 2. Upload CCCD mặt sau
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

      // 3. Upload từng giấy tờ ưu tiên, không gom nhiều ảnh vào một request
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
      emit(DormitoryRegistrationUploadError(e.toString()));
      return false;
    }
  }
}
