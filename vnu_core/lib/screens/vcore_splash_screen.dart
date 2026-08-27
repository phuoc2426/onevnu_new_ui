import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/admission/views/applicant_home_screen.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/applicant_session_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/screens/vcore_admission_view.dart';
import 'package:vnu_core/services/app_update_coordinator.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';

class VCoreSplashScreen extends StatefulWidget {
  final Widget mainScreen;

  const VCoreSplashScreen({
    super.key,
    required this.mainScreen,
  });

  @override
  State<VCoreSplashScreen> createState() => _VCoreSplashScreenState();
}

class _VCoreSplashScreenState extends State<VCoreSplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSplash());
  }

  Future<void> _initSplash() async {
    await _initDateFormatting();
    final firebaseToken = await _getFirebaseToken();

    try {
      final principalType =
          (await DataRepository().getSecureSaveKey(kSessionPrincipalType))
                  ?.trim()
                  .toUpperCase() ??
              '';

      if (principalType == kPrincipalTypeApplicant) {
        await _restoreApplicantSession(firebaseToken);
        return;
      }

      if (principalType == kPrincipalTypeUser) {
        await _restoreUserSession(firebaseToken);
        return;
      }

      // Tương thích dữ liệu đã lưu trước khi bổ sung principalType.
      final applicantSession = await ApplicantSessionRepository().load();
      if (applicantSession != null) {
        await DataRepository().saveSecureKey(
          kSessionPrincipalType,
          kPrincipalTypeApplicant,
        );
        await _restoreApplicantSession(firebaseToken);
        return;
      }

      final userValues = await Future.wait<String?>([
        DataRepository().getSecureSaveKey(kLoginToken),
        DataRepository().getSecureSaveKey(kLoginRefreshToken),
      ]);
      if ((userValues[0] ?? '').trim().isNotEmpty &&
          (userValues[1] ?? '').trim().isNotEmpty) {
        await DataRepository().saveSecureKey(
          kSessionPrincipalType,
          kPrincipalTypeUser,
        );
        await _restoreUserSession(firebaseToken);
        return;
      }

      await _clearAllSessions();
      _goToAdmission();
    } catch (error) {
      logError('Khởi tạo phiên đăng nhập lỗi: $error');
      await _clearAllSessions();
      _goToAdmission();
    }
  }

  Future<void> _restoreApplicantSession(String? firebaseToken) async {
    try {
      final session = await ApplicantSessionRepository().load();
      if (session == null) {
        throw StateError('Không tìm thấy refresh token của Applicant');
      }

      Globals().token = session.accessToken;
      Globals().refreshToken = session.refreshToken;
      ApiRepository().setToken(session.accessToken);

      final refreshed = await ApiRepository().applicantRefreshToken(
        session.refreshToken,
      );
      await ApplicantSessionRepository().save(refreshed);

      Globals().token = refreshed.accessToken;
      Globals().refreshToken = refreshed.refreshToken;
      ApiRepository().setToken(refreshed.accessToken);

      await _syncFirebaseToken(firebaseToken);
      _goToApplicantHome(refreshed.applicant.fullName);
    } catch (error) {
      logError('Khôi phục phiên Applicant lỗi: $error');
      await _clearAllSessions();
      _goToAdmission();
    }
  }

  Future<void> _restoreUserSession(String? firebaseToken) async {
    try {
      final values = await Future.wait<String?>([
        DataRepository().getSecureSaveKey(kLoginToken),
        DataRepository().getSecureSaveKey(kLoginRefreshToken),
      ]);
      final accessToken = values[0]?.trim() ?? '';
      final refreshToken = values[1]?.trim() ?? '';
      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw StateError('Không tìm thấy phiên đăng nhập người dùng');
      }

      Globals().token = accessToken;
      Globals().refreshToken = refreshToken;
      ApiRepository().setToken(accessToken);

      final response = await ApiRepository().refreshToken(refreshToken);
      final newAccessToken = response.accessToken?.trim() ?? '';
      final newRefreshToken = response.refreshToken?.trim() ?? '';
      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        throw StateError('Phản hồi refresh token không hợp lệ');
      }

      Globals().token = newAccessToken;
      Globals().refreshToken = newRefreshToken;
      ApiRepository().setToken(newAccessToken);

      await Future.wait<void>([
        DataRepository().saveSecureKey(kLoginToken, newAccessToken),
        DataRepository().saveSecureKey(kLoginRefreshToken, newRefreshToken),
        DataRepository().saveSecureKey(
          kSessionPrincipalType,
          kPrincipalTypeUser,
        ),
      ]);

      await _syncFirebaseToken(firebaseToken);
      _goToMain();
    } catch (error) {
      logError('Khôi phục phiên USER lỗi: $error');
      await _clearAllSessions();
      _goToAdmission();
    }
  }

  Future<void> _initDateFormatting() async {
    try {
      await initializeDateFormatting();
    } catch (error) {
      logError('Khởi tạo định dạng ngày lỗi: $error');
    }
  }

  Future<String?> _getFirebaseToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      if (Platform.isIOS) {
        await _waitForApnsToken(messaging);
      }

      final token = await messaging.getToken();
      if (token != null && token.trim().isNotEmpty) {
        // Do not overwrite ServicesUrl.firebaseToken here. addFirebaseToken()
        // needs the previous value to update oldToken -> newToken on server.
        logInfo('Đã lấy FCM token cho thiết bị');
        return token.trim();
      }
      return null;
    } catch (error) {
      logError('Không lấy được FCM token: $error');
      return null;
    }
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final token = await messaging.getAPNSToken();
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  Future<void> _syncFirebaseToken(String? firebaseToken) async {
    if (firebaseToken == null || firebaseToken.isEmpty) return;
    try {
      await VnuCore().addFirebaseToken(firebaseToken);
    } catch (error) {
      // Không chặn đăng nhập nếu cập nhật FCM token tạm thời thất bại.
      logError('Cập nhật FCM token lỗi: $error');
    }
  }

  Future<void> _clearAllSessions() async {
    try {
      await Globals().clearSession();
      ApiRepository().setToken('');
    } catch (error) {
      logError('Xóa phiên đăng nhập lỗi: $error');
    }
  }

  void _markPostSplashReadyAfterNavigation() {
    // Force Update may already be known while Splash is loading, but the
    // blocking UI must only appear after Splash has handed control to the real
    // application route. A short post-navigation settle also prevents the gate
    // from flashing over the final Splash transition frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        AppUpdateCoordinator.instance.markPostSplashReady();
      });
    });
  }

  void _goToAdmission() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VcoreAdmissionView()),
      (_) => false,
    );
    _markPostSplashReadyAfterNavigation();
  }

  void _goToApplicantHome(String fullName) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ApplicantHomeScreen(
          fullName: fullName.trim().isEmpty ? 'Thí sinh' : fullName,
        ),
      ),
      (_) => false,
    );
    _markPostSplashReadyAfterNavigation();
  }

  void _goToMain() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    if (VnuCore().loginSucces != null) {
      VnuCore().loginSucces!(Globals().token);
      _markPostSplashReadyAfterNavigation();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.mainScreen),
      (_) => false,
    );
    _markPostSplashReadyAfterNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 36, 30, 40),
          child: Image(
            image: AssetImage(
              'assets/images/ic_logo_vnu_full.png',
              package: 'vnu_noi_tru',
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}


