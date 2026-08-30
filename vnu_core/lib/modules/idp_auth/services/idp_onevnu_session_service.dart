import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/auth_mode/auth_entry_mode_service.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';

/// Nhận token ONEVNU sau khi redeem IdP ticket và gắn vào session hiện tại.
///
/// Service này KHÔNG lưu password IdP, KHÔNG lưu IdP access token và
/// KHÔNG lưu IdP refresh token trên Flutter.
class IdpOneVnuSessionService {
  IdpOneVnuSessionService._internal();

  static final IdpOneVnuSessionService _instance =
      IdpOneVnuSessionService._internal();

  factory IdpOneVnuSessionService() => _instance;

  Future<void> apply(SigninResponse response) async {
    final String accessToken = response.accessToken?.trim() ?? '';
    final String refreshToken = response.refreshToken?.trim() ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw StateError('Phiên ONEVNU nhận từ IdP không hợp lệ.');
    }

    // Giống mục tiêu của login cũ: không được giữ hồ sơ sinh viên của account trước.
    Globals().thongTinSinhVienModel.value = null;
    Globals().currentUserModel.value = null;
    Globals().lopDaoTaoModel.value = null;
    Globals().nienKhoaDaoTaoModel.value = null;

    await _clearApplicantLocalData();

    Globals().token = accessToken;
    Globals().refreshToken = refreshToken;
    ApiRepository().setToken(accessToken);

    final String username = _jwtSubject(accessToken);
    if (username.isNotEmpty) {
      Globals().usernameLogin = username;
    }

    final List<Future<void>> writes = <Future<void>>[
      DataRepository().saveSecureKey(kLoginToken, accessToken),
      DataRepository().saveSecureKey(kLoginRefreshToken, refreshToken),
      DataRepository().saveSecureKey(kSessionPrincipalType, kPrincipalTypeUser),
    ];

    if (username.isNotEmpty) {
      writes.add(DataRepository().saveSecureKey(kLoginUserName, username));
    }

    await Future.wait<void>(writes);

    // Dùng chính API profile hiện tại để kiểm tra token mới và nạp sinh viên.
    await Globals().refreshStudentInfo();

    if (Globals().thongTinSinhVienModel.value == null) {
      await Globals().clearSession(deleteUserLogin: false);
      ApiRepository().setToken('');
      throw StateError(
        'Đăng nhập IdP thành công nhưng không tải được thông tin sinh viên.',
      );
    }

    await AuthEntryModeService().markIdp();
  }

  Future<void> _clearApplicantLocalData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    const List<String> applicantKeys = <String>[
      'applicant_id',
      'applicant_cccd',
      'applicant_fullname',
      'applicant_email',
      'applicant_dob',
      'applicant_phone_number',
      'applicant_university_name',
      'applicant_phone',
    ];

    for (final String key in applicantKeys) {
      await prefs.remove(key);
    }
  }

  /// JWT do ONEVNU backend phát hành có subject là username.
  /// Chỉ dùng để khôi phục username local; không dùng kết quả này để xác thực token.
  String _jwtSubject(String token) {
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return '';

      final String normalized = base64Url.normalize(parts[1]);
      final String jsonText = utf8.decode(base64Url.decode(normalized));
      final Object? decoded = jsonDecode(jsonText);
      if (decoded is! Map) return '';

      final Object? subject = decoded['sub'];
      return subject is String ? subject.trim() : '';
    } catch (_) {
      return '';
    }
  }
}
