class RegistrationPayloadModel {
  final int registrationPeriodId;
  final List<int> priorityObjectIds;
  final int dormitoryId;
  final int? roomTypeId;
  final String status;
  final String reason;
  final int termType;
  final String? startDate;
  final String? endDate;
  final List<Object> attachmentFileIds;
  final RegistrationStudentPayload student;

  const RegistrationPayloadModel({
    required this.registrationPeriodId,
    this.priorityObjectIds = const <int>[],
    required this.dormitoryId,
    this.roomTypeId,
    required this.status,
    required this.reason,
    required this.termType,
    this.startDate,
    this.endDate,
    required this.attachmentFileIds,
    required this.student,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'registration_period_id': registrationPeriodId,
      'priority_object_ids': priorityObjectIds,
      'dormitory_id': dormitoryId,
      // API V2: room type is assigned by KTX staff. Keep nullable only for
      // backward compatibility; omit it from new requests when null.
      'room_type_id': roomTypeId,
      'status': status,
      'reason': reason,
      'term_type': termType,
      // Only valid for term_type = 5 (Khác).
      'start_date': startDate,
      'end_date': endDate,
      'attachment_file_ids': attachmentFileIds,
      'student': student.toJson(),
    };
    json.removeWhere((String key, dynamic value) => value == null);
    return json;
  }

  RegistrationPayloadModel copyWith({
    int? registrationPeriodId,
    List<int>? priorityObjectIds,
    int? dormitoryId,
    int? roomTypeId,
    bool clearRoomType = false,
    String? status,
    String? reason,
    int? termType,
    String? startDate,
    String? endDate,
    List<Object>? attachmentFileIds,
    RegistrationStudentPayload? student,
  }) {
    return RegistrationPayloadModel(
      registrationPeriodId: registrationPeriodId ?? this.registrationPeriodId,
      priorityObjectIds: priorityObjectIds ?? this.priorityObjectIds,
      dormitoryId: dormitoryId ?? this.dormitoryId,
      roomTypeId: clearRoomType ? null : (roomTypeId ?? this.roomTypeId),
      status: status ?? this.status,
      reason: reason ?? this.reason,
      termType: termType ?? this.termType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      attachmentFileIds: attachmentFileIds ?? this.attachmentFileIds,
      student: student ?? this.student,
    );
  }
}

class FamilyMemberPayload {
  final String relationship;
  final String fullName;
  final int? birthYear;
  final String? occupation;
  final String? phoneNumber;

  const FamilyMemberPayload({
    required this.relationship,
    required this.fullName,
    this.birthYear,
    this.occupation,
    this.phoneNumber,
  });

  factory FamilyMemberPayload.fromJson(Map<String, dynamic> json) {
    final dynamic rawBirthYear = json['birth_year'] ?? json['birthYear'];

    return FamilyMemberPayload(
      relationship: json['relationship']?.toString() ?? 'guardian',
      fullName: (json['full_name'] ?? json['fullName'])?.toString() ?? '',
      birthYear: rawBirthYear is num
          ? rawBirthYear.toInt()
          : int.tryParse(rawBirthYear?.toString() ?? ''),
      occupation: json['occupation']?.toString(),
      phoneNumber: (json['phone_number'] ?? json['phoneNumber'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'relationship': relationship,
      'full_name': fullName,
      'birth_year': birthYear,
      'occupation': occupation,
      'phone_number': phoneNumber,
    };

    json.removeWhere((String key, dynamic value) {
      return value == null || (value is String && value.trim().isEmpty);
    });

    return json;
  }

  String get relationshipLabel {
    switch (relationship) {
      case 'father':
        return 'Bố';
      case 'mother':
        return 'Mẹ';
      case 'guardian':
      default:
        return 'Người giám hộ';
    }
  }
}

class RegistrationStudentPayload {
  final String studentCode;
  final String fullName;
  final String dob;
  final String cccd;
  final String cccdIssueDate;
  final String? identityIssuePlace;
  final String? identityType;
  final String? identityName;
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
  final String gender;
  final String? ethnicity;
  final String? religion;
  final String phone;
  final String email;
  final List<FamilyMemberPayload> familyMembers;

  const RegistrationStudentPayload({
    required this.studentCode,
    required this.fullName,
    required this.dob,
    required this.cccd,
    required this.cccdIssueDate,
    this.identityIssuePlace,
    this.identityType,
    this.identityName,
    this.avatar,
    this.country,
    this.countryCode,
    this.national,
    required this.permanentAddress,
    this.vneidPermanentAddress,
    this.permanentProvinceCode,
    this.permanentWardCode,
    this.contactAddress,
    required this.className,
    this.faculty,
    required this.major,
    required this.academicYear,
    required this.system,
    required this.level,
    required this.universityName,
    this.univId,
    this.studentType,
    this.priorityObjectName,
    required this.temporaryAddress,
    this.vneidTemporaryAddress,
    this.temporaryProvinceCode,
    this.temporaryWardCode,
    this.reasonStay,
    required this.gender,
    this.ethnicity,
    this.religion,
    required this.phone,
    required this.email,
    this.familyMembers = const <FamilyMemberPayload>[],
  });

  factory RegistrationStudentPayload.fromJson(Map<String, dynamic> json) {
    final dynamic rawFamilyMembers =
        json['family_members'] ?? json['familyMembers'];

    return RegistrationStudentPayload(
      studentCode:
          (json['student_code'] ?? json['studentCode'])?.toString() ?? '',
      fullName: (json['full_name'] ?? json['fullName'])?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      cccd: (json['identity_no'] ?? json['identityNo'] ?? json['cccd'])
              ?.toString() ??
          '',
      cccdIssueDate: (json['identity_issue_date'] ??
                  json['identityIssueDate'] ??
                  json['cccd_issue_date'])
              ?.toString() ??
          '',
      identityIssuePlace:
          (json['identity_issue_place'] ?? json['identityIssuePlace'])
              ?.toString(),
      identityType:
          (json['identity_type'] ?? json['identityType'])?.toString(),
      identityName:
          (json['identity_name'] ?? json['identityName'])?.toString(),
      avatar:
          (json['avatar'] ?? json['avatar_url'] ?? json['avatarUrl'])?.toString(),
      country: json['country']?.toString(),
      countryCode:
          (json['country_code'] ?? json['countryCode'])?.toString(),
      national: (json['national'] ?? json['nationality'])?.toString(),
      permanentAddress: (json['permanent_address'] ??
                  json['permanentAddress'] ??
                  json['hometown'])
              ?.toString() ??
          '',
      vneidPermanentAddress:
          (json['vneid_permanent_address'] ?? json['vneidPermanentAddress'])
              ?.toString(),
      permanentProvinceCode:
          (json['permanent_province_code'] ?? json['permanentProvinceCode'])
              ?.toString(),
      permanentWardCode:
          (json['permanent_ward_code'] ?? json['permanentWardCode'])
              ?.toString(),
      contactAddress:
          (json['contact_address'] ?? json['contactAddress'])?.toString(),
      className: (json['class'] ?? json['class_name'])?.toString() ?? '',
      faculty: json['faculty']?.toString(),
      major: json['major']?.toString() ?? '',
      academicYear:
          (json['academic_year'] ?? json['academicYear'])?.toString() ?? '',
      system: json['system']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      universityName:
          (json['university_name'] ?? json['university'])?.toString() ?? '',
      univId: _toNullableInt(
        json['univ_id'] ?? json['univId'] ?? json['university_id'],
      ),
      studentType:
          _toNullableInt(json['student_type'] ?? json['studentType']),
      priorityObjectName:
          (json['priority_object_name'] ?? json['priorityObject'])?.toString(),
      temporaryAddress:
          (json['temporary_address'] ?? json['temporaryAddress'])?.toString() ??
              '',
      vneidTemporaryAddress:
          (json['vneid_temporary_address'] ?? json['vneidTemporaryAddress'])
              ?.toString(),
      temporaryProvinceCode:
          (json['temporary_province_code'] ?? json['temporaryProvinceCode'])
              ?.toString(),
      temporaryWardCode:
          (json['temporary_ward_code'] ?? json['temporaryWardCode'])
              ?.toString(),
      reasonStay: (json['reason_stay'] ?? json['reasonStay'])?.toString(),
      // Never silently convert unknown/null to male.
      gender: json['gender']?.toString() ?? '',
      ethnicity: json['ethnicity']?.toString(),
      religion: json['religion']?.toString(),
      phone: (json['phone_number'] ?? json['phoneNumber'] ?? json['phone'])
              ?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      familyMembers: rawFamilyMembers is List
          ? rawFamilyMembers
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) => FamilyMemberPayload.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <FamilyMemberPayload>[],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'student_code': studentCode.isEmpty ? null : studentCode,
      'full_name': fullName,
      'dob': dob,
      'identity_no': cccd,
      'identity_type': identityType,
      'identity_name': identityName,
      'identity_issue_date': cccdIssueDate.isEmpty ? null : cccdIssueDate,
      'identity_issue_place': identityIssuePlace,
      'country': country,
      'country_code': countryCode,
      'national': national,
      'permanent_address': permanentAddress,
      'vneid_permanent_address': vneidPermanentAddress,
      'permanent_province_code': permanentProvinceCode,
      'permanent_ward_code': permanentWardCode,
      'contact_address': contactAddress,
      'class': className,
      'faculty': faculty,
      'major': major,
      'academic_year': academicYear,
      'system': system,
      'level': level,
      'university_name': universityName,
      'univ_id': univId,
      'student_type': studentType,
      'priority_object_name': priorityObjectName,
      'temporary_address': temporaryAddress,
      'vneid_temporary_address': vneidTemporaryAddress,
      'temporary_province_code': temporaryProvinceCode,
      'temporary_ward_code': temporaryWardCode,
      'reason_stay': reasonStay,
      'gender': gender,
      'ethnicity': ethnicity,
      'religion': religion,
      'phone_number': phone,
      'email': email,
      'family_members':
          familyMembers.map((FamilyMemberPayload item) => item.toJson()).toList(),
    };

    json.removeWhere((String key, dynamic value) {
      return value == null || (value is String && value.trim().isEmpty);
    });
    return json;
  }

  /// Student fields accepted by POST /dormitory/registrations.
  ///
  /// Keep this separate from [toJson] because the draft/profile model carries
  /// more fields than the registration endpoint currently validates.
  Map<String, dynamic> toRegistrationJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'student_code': studentCode.isEmpty ? null : studentCode,
      'full_name': fullName,
      'dob': dob,
      'identity_no': cccd,
      'country_code': countryCode,
      'identity_issue_date': cccdIssueDate.isEmpty ? null : cccdIssueDate,
      'identity_issue_place': identityIssuePlace,
      'permanent_address': permanentAddress,
      'permanent_province_code': permanentProvinceCode,
      'permanent_ward_code': permanentWardCode,
      'contact_address': contactAddress,
      'class': className,
      'faculty': faculty,
      'major': major,
      'academic_year': academicYear,
      'system': system,
      'level': level,
      'university_name': universityName,
      'univ_id': univId,
      'student_type': studentType,
      'priority_object_name': priorityObjectName,
      'temporary_address': temporaryAddress,
      'temporary_province_code': temporaryProvinceCode,
      'temporary_ward_code': temporaryWardCode,
      'gender': gender,
      'ethnicity': ethnicity,
      'religion': religion,
      'phone_number': phone,
      'email': email,
      'family_members':
          familyMembers.map((FamilyMemberPayload item) => item.toJson()).toList(),
    };

    json.removeWhere((String key, dynamic value) {
      return value == null || (value is String && value.trim().isEmpty);
    });
    return json;
  }

  /// Fields supported by the current KTX PATCH /students/{identityNo}
  /// contract but not fully covered by POST /dormitory/registrations.
  ///
  /// This is intentionally a strict whitelist. Do not add academic fields here
  /// until UpdateStudentRequest in the KTX OpenAPI accepts them.
  Map<String, dynamic> toPostRegistrationUpdateJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'identity_type': identityType,
      'identity_name': identityName,
      'country': country,
      'country_code': countryCode,
      'national': national,
      'vneid_permanent_address': vneidPermanentAddress,
      'vneid_temporary_address': vneidTemporaryAddress,
      'reason_stay': reasonStay,
    };

    json.removeWhere((String key, dynamic value) {
      return value == null || (value is String && value.trim().isEmpty);
    });
    return json;
  }

  /// Student fields accepted by POST /dormitory/attachments/upload.
  Map<String, dynamic> toUploadJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'student_code': studentCode.isEmpty ? null : studentCode,
      'full_name': fullName,
      'dob': dob,
      'identity_no': cccd,
      'identity_issue_date': cccdIssueDate.isEmpty ? null : cccdIssueDate,
      'permanent_address': permanentAddress,
      'class': className,
      'major': major,
      'academic_year': academicYear,
      'system': system,
      'level': level,
      'university_name': universityName,
      'priority_object_name': priorityObjectName,
      'temporary_address': temporaryAddress,
      'gender': gender,
      'phone_number': phone,
      'email': email,
    };

    json.removeWhere((String key, dynamic value) {
      return value == null || (value is String && value.trim().isEmpty);
    });
    return json;
  }

  static int? _toNullableInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
