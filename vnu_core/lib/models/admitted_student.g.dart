// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admitted_student.dart';

AdmittedStudent _$AdmittedStudentFromJson(Map<String, dynamic> json) {
  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  int? parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  return AdmittedStudent(
    id: parseInt(json['applicantId'] ?? json['id']),
    cccd: (json['cccd'] ?? '').toString(),
    fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
    dob: parseDate(json['dob']),
    phoneNumber: (json['phoneNumber'] ?? json['phone_number'])?.toString(),
    email: json['email']?.toString(),
    universityName:
        (json['universityName'] ?? json['university_name'])?.toString(),
    isActive: json['isActive'] as bool? ?? json['is_active'] as bool?,
    mappedStudentId:
        parseInt(json['mappedStudentId'] ?? json['mapped_student_id']),
    lastLoginAt:
        parseDate(json['lastLoginAt'] ?? json['last_login_at']),
    createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
  );
}

Map<String, dynamic> _$AdmittedStudentToJson(AdmittedStudent instance) =>
    <String, dynamic>{
      'applicantId': instance.id,
      'cccd': instance.cccd,
      'fullName': instance.fullName,
      'dob': instance.dob?.toIso8601String(),
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'universityName': instance.universityName,
      'isActive': instance.isActive,
      'mappedStudentId': instance.mappedStudentId,
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
