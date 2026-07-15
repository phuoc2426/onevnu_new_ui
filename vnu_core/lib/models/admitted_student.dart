import 'package:json_annotation/json_annotation.dart';

part 'admitted_student.g.dart';

@JsonSerializable()
class AdmittedStudent {
  final int? id;
  final String cccd;
  @JsonKey(name: 'full_name')
  final String fullName;
  final DateTime? dob;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String? email;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  AdmittedStudent({
    this.id,
    required this.cccd,
    required this.fullName,
    this.dob,
    this.phoneNumber,
    this.email,
    this.createdAt,
  });

  factory AdmittedStudent.fromJson(Map<String, dynamic> json) =>
      _$AdmittedStudentFromJson(json);
  Map<String, dynamic> toJson() => _$AdmittedStudentToJson(this);
}
