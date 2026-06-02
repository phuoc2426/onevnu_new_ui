class RegistrationPayloadModel {
  final int registrationPeriodId;
  final int? priorityObjectId;
  final int dormitoryId;
  final int roomTypeId;
  final String status; // "draft" hoặc "pending"
  final String reason;
  final List<Object> attachmentFileIds;
  final RegistrationStudentPayload student;

  RegistrationPayloadModel({
    required this.registrationPeriodId,
    this.priorityObjectId,
    required this.dormitoryId,
    required this.roomTypeId,
    required this.status,
    required this.reason,
    required this.attachmentFileIds,
    required this.student,
  });

  Map<String, dynamic> toJson() => {
    'registration_period_id': registrationPeriodId,
    'priority_object_id': priorityObjectId,
    'dormitory_id': dormitoryId,
    'room_type_id': roomTypeId,
    'status': status,
    'reason': reason,
    'attachment_file_ids': attachmentFileIds,
    'student': student.toJson(),
  };

  RegistrationPayloadModel copyWith({
    int? registrationPeriodId,
    int? priorityObjectId,
    int? dormitoryId,
    int? roomTypeId,
    String? status,
    String? reason,
    List<Object>? attachmentFileIds,
    RegistrationStudentPayload? student,
  }) {
    return RegistrationPayloadModel(
      registrationPeriodId: registrationPeriodId ?? this.registrationPeriodId,
      priorityObjectId: priorityObjectId ?? this.priorityObjectId,
      dormitoryId: dormitoryId ?? this.dormitoryId,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      attachmentFileIds: attachmentFileIds ?? this.attachmentFileIds,
      student: student ?? this.student,
    );
  }
}

class RegistrationStudentPayload {
  final String studentCode;
  final String fullName;
  final String dob; // format e.g. "2003-05-20T00:00:00Z"
  final String cccd;
  final String cccdIssueDate; // format e.g. "2021-01-01T00:00:00Z"
  final String hometown;
  final String className; // map to 'class' in JSON
  final String major;
  final String academicYear;
  final String system;
  final String level;
  final String universityName;
  final String? priorityObjectName;
  final String temporaryAddress;
  final String gender; // "male" / "female"
  final String phone;
  final String email;

  RegistrationStudentPayload({
    required this.studentCode,
    required this.fullName,
    required this.dob,
    required this.cccd,
    required this.cccdIssueDate,
    required this.hometown,
    required this.className,
    required this.major,
    required this.academicYear,
    required this.system,
    required this.level,
    required this.universityName,
    this.priorityObjectName,
    required this.temporaryAddress,
    required this.gender,
    required this.phone,
    required this.email,
  });

  factory RegistrationStudentPayload.fromJson(Map<String, dynamic> json) {
    return RegistrationStudentPayload(
      studentCode: json['student_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      cccd: json['cccd'] as String? ?? '',
      cccdIssueDate: json['cccd_issue_date'] as String? ?? '',
      hometown: json['hometown'] as String? ?? '',
      className: (json['class'] ?? json['class_name']) as String? ?? '',
      major: json['major'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '',
      system: json['system'] as String? ?? '',
      level: json['level'] as String? ?? '',
      universityName: json['university_name'] as String? ?? '',
      priorityObjectName: json['priority_object_name'] as String?,
      temporaryAddress: json['temporary_address'] as String? ?? '',
      gender: json['gender'] as String? ?? 'male',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'student_code': studentCode,
    'full_name': fullName,
    'dob': dob,
    'cccd': cccd,
    'cccd_issue_date': cccdIssueDate,
    'hometown': hometown,
    'class': className,
    'major': major,
    'academic_year': academicYear,
    'system': system,
    'level': level,
    'university_name': universityName,
    'priority_object_name': priorityObjectName,
    'temporary_address': temporaryAddress,
    'gender': gender,
    'phone': phone,
    'email': email,
  };
}
