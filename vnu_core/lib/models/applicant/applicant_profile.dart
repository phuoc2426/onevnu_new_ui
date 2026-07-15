import 'dart:convert';

class ApplicantProfile {
  final int? id;
  final String? identityNo;
  final DateTime? identityIssueDate;
  final String? fullName;
  final DateTime? dob;
  final String? gender;
  final String? phoneNumber;
  final String? email;
  final String? permanentAddress;
  final String? temporaryAddress;
  final String? studentCode;
  final String? className;
  final String? major;
  final String? academicYear;
  final String? system;
  final String? level;
  final String? universityName;
  final int? univId;
  final String? priorityObjectName;
  final List<dynamic>? registrationIds;

  ApplicantProfile({
    this.id,
    this.identityNo,
    this.identityIssueDate,
    this.fullName,
    this.dob,
    this.gender,
    this.phoneNumber,
    this.email,
    this.permanentAddress,
    this.temporaryAddress,
    this.studentCode,
    this.className,
    this.major,
    this.academicYear,
    this.system,
    this.level,
    this.universityName,
    this.univId,
    this.priorityObjectName,
    this.registrationIds,
  });

  factory ApplicantProfile.fromJson(Map<String, dynamic> json) {
    return ApplicantProfile(
      id: json['id'] as int?,
      identityNo: json['identityNo'] as String?,
      identityIssueDate: json['identityIssueDate'] != null
          ? DateTime.parse(json['identityIssueDate'] as String)
          : null,
      fullName: json['fullName'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      permanentAddress: json['permanentAddress'] as String?,
      temporaryAddress: json['temporaryAddress'] as String?,
      studentCode: json['studentCode'] as String?,
      className: json['className'] as String?,
      major: json['major'] as String?,
      academicYear: json['academicYear'] as String?,
      system: json['system'] as String?,
      level: json['level'] as String?,
      universityName: json['universityName'] as String?,
      univId: json['univId'] as int?,
      priorityObjectName: json['priorityObjectName'] as String?,
      registrationIds: json['registrationIds'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identityNo': identityNo,
      'identityIssueDate': identityIssueDate?.toIso8601String(),
      'fullName': fullName,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'phoneNumber': phoneNumber,
      'email': email,
      'permanentAddress': permanentAddress,
      'temporaryAddress': temporaryAddress,
      'studentCode': studentCode,
      'className': className,
      'major': major,
      'academicYear': academicYear,
      'system': system,
      'level': level,
      'universityName': universityName,
      'univId': univId,
      'priorityObjectName': priorityObjectName,
      'registrationIds': registrationIds,
    };
  }
}
