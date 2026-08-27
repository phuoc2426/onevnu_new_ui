import 'package:vnu_noi_tru/domain/registration/dormitory_date_codec.dart';
import 'package:vnu_noi_tru/models/dormitory_registration/registration_payload_model.dart';

/// Single source of truth for the student section of a dormitory registration.
///
/// Account/Globals/applicant data may seed this object once. Review, upload and
/// submit must read this draft instead of consulting those external sources.
class DormitoryStudentDraft {
  const DormitoryStudentDraft({
    this.studentCode = '',
    this.fullName = '',
    this.dob = '',
    this.gender,
    this.identityNo = '',
    this.identityType,
    this.identityName,
    this.identityIssueDate = '',
    this.identityIssuePlace,
    this.avatar,
    this.country,
    this.countryCode,
    this.national,
    this.permanentAddress = '',
    this.vneidPermanentAddress,
    this.permanentProvinceCode,
    this.permanentWardCode,
    this.contactAddress,
    this.className = '',
    this.faculty,
    this.major = '',
    this.academicYear = '',
    this.system = '',
    this.level = '',
    this.universityName = '',
    this.univId,
    this.studentType,
    this.priorityObjectName,
    this.temporaryAddress = '',
    this.vneidTemporaryAddress,
    this.temporaryProvinceCode,
    this.temporaryWardCode,
    this.reasonStay,
    this.ethnicity,
    this.religion,
    this.phone = '',
    this.email = '',
    this.familyMembers = const <FamilyMemberPayload>[],
  });

  final String studentCode;
  final String fullName;
  final String dob;
  final String? gender;
  final String identityNo;
  final String? identityType;
  final String? identityName;
  final String identityIssueDate;
  final String? identityIssuePlace;
  final String? avatar;
  final String? country;
  final String? countryCode;
  final String? national;
  final String permanentAddress;
  final String? vneidPermanentAddress;
  final String? permanentProvinceCode;
  final String? permanentWardCode;
  final String? contactAddress;
  final String className;
  final String? faculty;
  final String major;
  final String academicYear;
  final String system;
  final String level;
  final String universityName;
  final int? univId;
  final int? studentType;
  final String? priorityObjectName;
  final String temporaryAddress;
  final String? vneidTemporaryAddress;
  final String? temporaryProvinceCode;
  final String? temporaryWardCode;
  final String? reasonStay;
  final String? ethnicity;
  final String? religion;
  final String phone;
  final String email;
  final List<FamilyMemberPayload> familyMembers;

  factory DormitoryStudentDraft.fromPayload(RegistrationStudentPayload value) {
    return DormitoryStudentDraft(
      studentCode: value.studentCode,
      fullName: value.fullName,
      dob: DormitoryDateCodec.normalize(value.dob),
      gender: value.gender.trim().isEmpty ? null : value.gender,
      identityNo: value.cccd,
      identityType: value.identityType,
      identityName: value.identityName,
      identityIssueDate: DormitoryDateCodec.normalize(value.cccdIssueDate),
      identityIssuePlace: value.identityIssuePlace,
      avatar: value.avatar,
      country: value.country,
      countryCode: value.countryCode,
      national: value.national,
      permanentAddress: value.permanentAddress,
      vneidPermanentAddress: value.vneidPermanentAddress,
      permanentProvinceCode: value.permanentProvinceCode,
      permanentWardCode: value.permanentWardCode,
      contactAddress: value.contactAddress,
      className: value.className,
      faculty: value.faculty,
      major: value.major,
      academicYear: value.academicYear,
      system: value.system,
      level: value.level,
      universityName: value.universityName,
      univId: value.univId,
      studentType: value.studentType,
      priorityObjectName: value.priorityObjectName,
      temporaryAddress: value.temporaryAddress,
      vneidTemporaryAddress: value.vneidTemporaryAddress,
      temporaryProvinceCode: value.temporaryProvinceCode,
      temporaryWardCode: value.temporaryWardCode,
      reasonStay: value.reasonStay,
      ethnicity: value.ethnicity,
      religion: value.religion,
      phone: value.phone,
      email: value.email,
      familyMembers: List<FamilyMemberPayload>.unmodifiable(value.familyMembers),
    );
  }

  factory DormitoryStudentDraft.fromJson(Map<String, dynamic> json) {
    final RegistrationStudentPayload payload =
        RegistrationStudentPayload.fromJson(json);
    return DormitoryStudentDraft.fromPayload(payload);
  }

  RegistrationStudentPayload toPayload({String? priorityObjectName}) {
    return RegistrationStudentPayload(
      studentCode: studentCode.trim(),
      fullName: fullName.trim(),
      dob: DormitoryDateCodec.normalize(dob),
      cccd: identityNo.trim(),
      cccdIssueDate: DormitoryDateCodec.normalize(identityIssueDate),
      identityIssuePlace: _trimOrNull(identityIssuePlace),
      identityType: _trimOrNull(identityType),
      identityName: _trimOrNull(identityName),
      avatar: _trimOrNull(avatar),
      country: _trimOrNull(country),
      countryCode: _trimOrNull(countryCode),
      national: _trimOrNull(national),
      permanentAddress: permanentAddress.trim(),
      vneidPermanentAddress: _trimOrNull(vneidPermanentAddress),
      permanentProvinceCode: _trimOrNull(permanentProvinceCode),
      permanentWardCode: _trimOrNull(permanentWardCode),
      contactAddress: _trimOrNull(contactAddress),
      className: className.trim(),
      faculty: _trimOrNull(faculty),
      major: major.trim(),
      academicYear: academicYear.trim(),
      system: system.trim(),
      level: level.trim(),
      universityName: universityName.trim(),
      univId: univId,
      studentType: studentType,
      priorityObjectName:
          _trimOrNull(priorityObjectName) ?? _trimOrNull(this.priorityObjectName),
      temporaryAddress: temporaryAddress.trim(),
      vneidTemporaryAddress: _trimOrNull(vneidTemporaryAddress),
      temporaryProvinceCode: _trimOrNull(temporaryProvinceCode),
      temporaryWardCode: _trimOrNull(temporaryWardCode),
      reasonStay: _trimOrNull(reasonStay),
      gender: gender?.trim() ?? '',
      ethnicity: _trimOrNull(ethnicity),
      religion: _trimOrNull(religion),
      phone: phone.trim(),
      email: email.trim(),
      familyMembers: List<FamilyMemberPayload>.unmodifiable(familyMembers),
    );
  }

  List<String> validationErrors() {
    final List<String> errors = <String>[];
    if (fullName.trim().isEmpty) errors.add('Họ và tên');
    if (DormitoryDateCodec.normalize(dob).isEmpty) errors.add('Ngày sinh');
    if (identityNo.trim().isEmpty) errors.add('Số CCCD/CMND');
    if ((gender ?? '').trim().isEmpty) errors.add('Giới tính');
    if (phone.trim().isEmpty) errors.add('Số điện thoại');
    if (email.trim().isEmpty) errors.add('Email');
    if (familyMembers.isEmpty) errors.add('Thông tin gia đình');
    return errors;
  }

  DormitoryStudentDraft copyWith({
    String? studentCode,
    String? fullName,
    String? dob,
    String? gender,
    bool clearGender = false,
    String? identityNo,
    String? identityType,
    String? identityName,
    String? identityIssueDate,
    String? identityIssuePlace,
    String? avatar,
    String? country,
    String? countryCode,
    String? national,
    String? permanentAddress,
    String? vneidPermanentAddress,
    String? permanentProvinceCode,
    String? permanentWardCode,
    String? contactAddress,
    String? className,
    String? faculty,
    String? major,
    String? academicYear,
    String? system,
    String? level,
    String? universityName,
    int? univId,
    bool clearUnivId = false,
    int? studentType,
    bool clearStudentType = false,
    String? priorityObjectName,
    String? temporaryAddress,
    String? vneidTemporaryAddress,
    String? temporaryProvinceCode,
    String? temporaryWardCode,
    String? reasonStay,
    String? ethnicity,
    String? religion,
    String? phone,
    String? email,
    List<FamilyMemberPayload>? familyMembers,
  }) {
    return DormitoryStudentDraft(
      studentCode: studentCode ?? this.studentCode,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: clearGender ? null : (gender ?? this.gender),
      identityNo: identityNo ?? this.identityNo,
      identityType: identityType ?? this.identityType,
      identityName: identityName ?? this.identityName,
      identityIssueDate: identityIssueDate ?? this.identityIssueDate,
      identityIssuePlace: identityIssuePlace ?? this.identityIssuePlace,
      avatar: avatar ?? this.avatar,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      national: national ?? this.national,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      vneidPermanentAddress:
          vneidPermanentAddress ?? this.vneidPermanentAddress,
      permanentProvinceCode:
          permanentProvinceCode ?? this.permanentProvinceCode,
      permanentWardCode: permanentWardCode ?? this.permanentWardCode,
      contactAddress: contactAddress ?? this.contactAddress,
      className: className ?? this.className,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      academicYear: academicYear ?? this.academicYear,
      system: system ?? this.system,
      level: level ?? this.level,
      universityName: universityName ?? this.universityName,
      univId: clearUnivId ? null : (univId ?? this.univId),
      studentType:
          clearStudentType ? null : (studentType ?? this.studentType),
      priorityObjectName: priorityObjectName ?? this.priorityObjectName,
      temporaryAddress: temporaryAddress ?? this.temporaryAddress,
      vneidTemporaryAddress:
          vneidTemporaryAddress ?? this.vneidTemporaryAddress,
      temporaryProvinceCode:
          temporaryProvinceCode ?? this.temporaryProvinceCode,
      temporaryWardCode: temporaryWardCode ?? this.temporaryWardCode,
      reasonStay: reasonStay ?? this.reasonStay,
      ethnicity: ethnicity ?? this.ethnicity,
      religion: religion ?? this.religion,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      familyMembers: familyMembers ?? this.familyMembers,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = toPayload().toJson();
    // Keep nullable draft-only state explicit so null gender survives cache.
    json['gender'] = gender;
    return json;
  }

  static String? _trimOrNull(String? value) {
    final String text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
