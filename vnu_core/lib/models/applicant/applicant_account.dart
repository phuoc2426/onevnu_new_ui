import 'dart:convert';

class ApplicantAccount {
  final int? id;
  final String guid;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool isActive;
  final List<dynamic>? registrationIds;

  ApplicantAccount({
    this.id,
    required this.guid,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.isActive,
    this.registrationIds,
  });

  factory ApplicantAccount.fromJson(Map<String, dynamic> json) {
    return ApplicantAccount(
      id: json['id'] as int?,
      guid: json['guid'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool,
      registrationIds: json['registrationIds'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guid': guid,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'registrationIds': registrationIds,
    };
  }
}
