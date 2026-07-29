import 'package:shared_preferences/shared_preferences.dart';

import '../models/admitted_student.dart';
import '../models/applicant_signin_response.dart';
import 'data_repository.dart';

class ApplicantStoredSession {
  final String accessToken;
  final String refreshToken;
  final String fullName;

  const ApplicantStoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.fullName,
  });
}

class ApplicantSessionRepository {
  ApplicantSessionRepository._internal();

  static final ApplicantSessionRepository _instance =
      ApplicantSessionRepository._internal();

  factory ApplicantSessionRepository() => _instance;

  Future<void> save(ApplicantSigninResponse response) async {
    final storage = DataRepository();

    // Không để phiên USER và APPLICANT cùng tồn tại gây chọn nhầm ở splash.
    await storage.deleteSecureKey(kLoginToken);
    await storage.deleteSecureKey(kLoginRefreshToken);

    await storage.saveSecureKey(
      kApplicantAccessToken,
      response.accessToken,
    );
    await storage.saveSecureKey(
      kApplicantRefreshToken,
      response.refreshToken,
    );
    await storage.saveSecureKey(
      kSessionPrincipalType,
      kPrincipalTypeApplicant,
    );

    await _saveProfile(response.applicant);
  }

  Future<ApplicantStoredSession?> load() async {
    final storage = DataRepository();
    final values = await Future.wait<String?>([
      storage.getSecureSaveKey(kApplicantAccessToken),
      storage.getSecureSaveKey(kApplicantRefreshToken),
    ]);

    final accessToken = values[0]?.trim() ?? '';
    final refreshToken = values[1]?.trim() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    return ApplicantStoredSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      fullName: prefs.getString('applicant_fullname') ?? 'Thí sinh',
    );
  }

  Future<void> clear() async {
    final storage = DataRepository();
    await storage.deleteSecureKey(kApplicantAccessToken);
    await storage.deleteSecureKey(kApplicantRefreshToken);

    final principalType =
        await storage.getSecureSaveKey(kSessionPrincipalType);
    if (principalType == kPrincipalTypeApplicant) {
      await storage.deleteSecureKey(kSessionPrincipalType);
    }

    final prefs = await SharedPreferences.getInstance();
    for (final key in const [
      'applicant_id',
      'applicant_cccd',
      'applicant_fullname',
      'applicant_phone_number',
      'applicant_email',
      'applicant_university_name',
      'applicant_dob',
    ]) {
      await prefs.remove(key);
    }
  }

  Future<void> _saveProfile(AdmittedStudent applicant) async {
    final prefs = await SharedPreferences.getInstance();
    if (applicant.id != null) {
      await prefs.setInt('applicant_id', applicant.id!);
    }
    await prefs.setString('applicant_cccd', applicant.cccd);
    await prefs.setString('applicant_fullname', applicant.fullName);
    await _setNullableString(
      prefs,
      'applicant_phone_number',
      applicant.phoneNumber,
    );
    await _setNullableString(prefs, 'applicant_email', applicant.email);
    await _setNullableString(
      prefs,
      'applicant_university_name',
      applicant.universityName,
    );
    await _setNullableString(
      prefs,
      'applicant_dob',
      applicant.dob?.toIso8601String(),
    );
  }

  Future<void> _setNullableString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value.trim());
    }
  }
}
