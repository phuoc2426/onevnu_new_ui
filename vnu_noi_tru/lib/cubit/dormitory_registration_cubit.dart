import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';
import 'package:dio/dio.dart';

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

  static const Map<String, dynamic> _emptyMyRegistrationsData = {
    'student': null,
    'accommodations': [],
    'histories': [],
  };

  UploadedAttachmentModel? cccdFrontAttachment;
  UploadedAttachmentModel? cccdBackAttachment;
  List<UploadedAttachmentModel> proofAttachments = [];

  File? cccdFrontFile;
  File? cccdBackFile;
  List<File> proofFiles = [];

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
    final mentionsStudent = text.contains('student') ||
        text.contains('student_code') ||
        text.contains('mã sinh viên') ||
        text.contains('ma sinh vien') ||
        text.contains('sinh viên') ||
        text.contains('sinh vien');
    final mentionsNotFound = text.contains('not found') ||
        text.contains('không tồn tại') ||
        text.contains('khong ton tai') ||
        text.contains('không tìm thấy') ||
        text.contains('khong tim thay');

    return (statusCode == 404 && mentionsStudent) ||
        (statusCode == 422 && mentionsStudent && mentionsNotFound) ||
        (mentionsStudent && mentionsNotFound);
  }

  void _emitEmptyMyRegistrations() {
    emit(DormitoryRegistrationMyRegistrationsLoaded(_emptyMyRegistrationsData));
  }

  RegistrationStudentPayload _buildStudentPayload() {
    final s = Globals().thongTinSinhVienModel.value;
    String formatDate(dynamic d) {
      if (d == null) return '';
      if (d is DateTime) return d.toIso8601String().split('T').first;
      return d.toString();
    }

    return RegistrationStudentPayload(
      studentCode: s?.maSinhVien ?? '',
      fullName: s?.hoVaTen ?? '',
      dob: formatDate(s?.ngaySinh),
      cccd: tempCccd ?? s?.soCmtCccd ?? '',
      cccdIssueDate: tempCccdIssueDate ?? formatDate(s?.ngayCapCmtCccd),
      hometown: tempHometown ?? s?.hoKhauThuongTruPhuongXa ?? '',
      className: Globals().lopDaoTaoModel.value?.ten ?? '',
      major: Globals().lopDaoTaoModel.value?.idNganhDaoTao ?? '',
      academicYear: Globals().nienKhoaDaoTaoModel.value?.ten ?? '',
      system: '',
      level: '',
      universityName: '',
      priorityObjectName: selectedPriorityObject?.name,
      temporaryAddress: tempTemporaryAddress ?? s?.diaChiLienLacPhuongXa ?? '',
      gender: (s?.gioiTinh ?? 'male').toLowerCase() == 'female'
          ? 'female'
          : 'male',
      phone: tempPhone ?? s?.mobile ?? s?.tel ?? '',
      email: tempEmail ?? s?.email ?? '',
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

  Future<void> getRegistrationPeriods() async {
    emit(DormitoryRegistrationLoading());
    try {
      final res = await _repository.getRegistrationPeriods();
      periods = res.data?.items ?? [];
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
      final code = studentCode ??
          Globals().thongTinSinhVienModel.value?.maSinhVien ??
          '';

      if (code.isEmpty) {
        emit(DormitoryRegistrationDismissHub());
        _emitEmptyMyRegistrations();
        return;
      }

      final res = await _repository.getMyRegistrations(
        studentCode: code,
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
  Future<void> getRegistrationDetail(int id) async {
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

  Future<void> getRegistrationHistories(int id) async {
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
      final studentPayload = _buildStudentPayload();
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
      final studentPayload = _buildStudentPayload();
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
      final studentPayload = _buildStudentPayload();
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

  Future<void> submitDraft(int id) async {
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
    emit(DormitoryRegistrationFileSelected('cccd_front', file));
  }

  void selectCCCDBack(File file) {
    cccdBackFile = file;
    emit(DormitoryRegistrationFileSelected('cccd_back', file));
  }

  void addProofFile(File file) {
    proofFiles.add(file);
    emit(DormitoryRegistrationFileSelected('proof', file));
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
      final studentPayload = _buildStudentPayload();
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

      // 3. Upload các giấy tờ ưu tiên cùng lúc
      if (proofFiles.isNotEmpty) {
        emit(
          DormitoryRegistrationUploadProgress(
            currentStep / totalSteps,
            "Đang tải lên tài liệu minh chứng (${(currentStep / totalSteps * 100).toInt()}%)...",
          ),
        );
        final res = await _repository.uploadAttachment(
          student: studentPayload,
          files: proofFiles,
        );
        if (res.data != null && res.data!.isNotEmpty) {
          proofAttachments.addAll(res.data!);
          proofFiles.clear();
          currentStep++;
          emit(
            DormitoryRegistrationUploadProgress(
              currentStep / totalSteps,
              "Đang tải lên tài liệu minh chứng (${(currentStep / totalSteps * 100).toInt()}%)...",
            ),
          );
        } else {
          throw Exception(
            'Không nhận được thông tin file sau khi upload tài liệu ưu tiên',
          );
        }
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
