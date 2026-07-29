import 'package:json_annotation/json_annotation.dart';

part 'admitted_student.g.dart';

@JsonSerializable()
class AdmittedStudent {
  final int? id;
  final String cccd;
  final String fullName;
  final DateTime? dob;
  final String? phoneNumber;
  final String? email;
  final String? universityName;
  final bool? isActive;
  final int? mappedStudentId;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdmittedStudent({
    this.id,
    required this.cccd,
    required this.fullName,
    this.dob,
    this.phoneNumber,
    this.email,
    this.universityName,
    this.isActive,
    this.mappedStudentId,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AdmittedStudent.fromJson(Map<String, dynamic> json) =>
      _$AdmittedStudentFromJson(json);

  Map<String, dynamic> toJson() => _$AdmittedStudentToJson(this);
}
