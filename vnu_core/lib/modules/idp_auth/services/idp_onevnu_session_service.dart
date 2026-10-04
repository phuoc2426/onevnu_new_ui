import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/auth_mode/auth_entry_mode_service.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/vnu_core.dart';

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

    // IdP redeem đã thành công ở thời điểm này. Tải profile trực tiếp để
    // không bị Globals.refreshStudentInfo() nuốt mất exception gốc.
    try {
      await _loadStudentProfileAfterIdp();
    } catch (error, stackTrace) {
      await Globals().clearSession(deleteUserLogin: false);
      ApiRepository().setToken('');
      Error.throwWithStackTrace(error, stackTrace);
    }

    await AuthEntryModeService().markIdp();

    // IDP authentication is complete before FCM is touched. This also repairs
    // sessions that reuse the same cached FCM token after a fresh IDP login.
    unawaited(_syncFcmAfterIdpLogin());
  }

  Future<void> _loadStudentProfileAfterIdp() async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final StudentInfoModel student =
            await ApiRepository().getSinhVienInfo();

        Globals().thongTinSinhVienModel.value = student;
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        logError(
          '[IDP_SESSION] GET /api/sinhvien failed '
          'attempt=$attempt type=${error.runtimeType} error=$error',
        );

        if (attempt < 3) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * attempt),
          );
        }
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  Future<void> _clearApplicantLocalData() async {
    await Future.wait<void>(<Future<void>>[
      DataRepository().deleteSecureKey(kApplicantAccessToken),
      DataRepository().deleteSecureKey(kApplicantRefreshToken),
    ]);

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


  Future<void> _syncFcmAfterIdpLogin() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        for (int attempt = 0; attempt < 8; attempt++) {
          final String? apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null && apnsToken.trim().isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }

      final String? firebaseToken = await messaging.getToken();
      await VnuCore().addFirebaseToken(firebaseToken);
    } catch (error, stackTrace) {
      logError(
        '[FCM][IDP_LOGIN] post-login binding failed: '
        '$error\n$stackTrace',
      );
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
