import 'admitted_student.dart';

class ApplicantSigninResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String principalType;
  final AdmittedStudent applicant;

  const ApplicantSigninResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.principalType,
    required this.applicant,
  });

  factory ApplicantSigninResponse.fromJson(Map<String, dynamic> json) {
    final applicantJson = json['applicant'];
    if (applicantJson is! Map) {
      throw const FormatException(
        'Phản hồi đăng nhập Applicant thiếu thông tin thí sinh',
      );
    }

    final accessToken = (json['accessToken'] ?? '').toString().trim();
    final refreshToken = (json['refreshToken'] ?? '').toString().trim();
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException(
        'Phản hồi đăng nhập Applicant thiếu access token hoặc refresh token',
      );
    }

    return ApplicantSigninResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: (json['tokenType'] ?? 'Bearer').toString(),
      principalType: (json['principalType'] ?? 'APPLICANT').toString(),
      applicant: AdmittedStudent.fromJson(
        Map<String, dynamic>.from(applicantJson),
      ),
    );
  }
}
