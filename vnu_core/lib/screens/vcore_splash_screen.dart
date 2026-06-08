import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/admission/views/vcore_admission_view.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';

import '../globals.dart';

class VCoreSplashScreen extends StatefulWidget {
  final Widget mainScreen;

  const VCoreSplashScreen({
    Key? key,
    required this.mainScreen,
  }) : super(key: key);

  @override
  State<VCoreSplashScreen> createState() => _VCoreSplashScreenState();
}

class _VCoreSplashScreenState extends State<VCoreSplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSplash();
    });
  }

  Future<void> _initSplash() async {
    await _initDateFormatting();

    final firebaseToken = await _getFirebaseToken();

    String token = '';
    String refreshToken = '';

    try {
      final results = await Future.wait([
        DataRepository().getSecureSaveKey(kLoginToken),
        DataRepository().getSecureSaveKey(kLoginRefreshToken),
      ]);

      token = results[0] ?? '';
      refreshToken = results[1] ?? '';
    } catch (e) {
      logError(e.toString());
    }

    if (!mounted) return;

    if (token.isEmpty || refreshToken.isEmpty) {
      await _clearLoginSession();
      _goToAdmission();
      return;
    }

    Globals().token = token;
    Globals().refreshToken = refreshToken;

    await _refreshTokenAndGoMain(firebaseToken);
  }

  Future<void> _initDateFormatting() async {
    try {
      await initializeDateFormatting();
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<String?> _getFirebaseToken() async {
    try {
      final firebaseToken = await FirebaseMessaging.instance.getToken();
      logInfo('FCM token: ${firebaseToken.toString()}');
      return firebaseToken;
    } catch (e) {
      logError('FCM lỗi: ${e.toString()}');
      return null;
    }
  }

  Future<void> _refreshTokenAndGoMain(String? firebaseToken) async {
    try {
      final responseRefreshToken =
      await ApiRepository().refreshToken(Globals().refreshToken);

      final newToken = responseRefreshToken.accessToken ?? '';
      final newRefreshToken = responseRefreshToken.refreshToken ?? '';

      if (newToken.isEmpty || newRefreshToken.isEmpty) {
        throw Exception('Refresh token response is empty');
      }

      Globals().token = newToken;
      Globals().refreshToken = newRefreshToken;

      await DataRepository().saveSecureKey(kLoginToken, Globals().token);
      await DataRepository().saveSecureKey(
        kLoginRefreshToken,
        Globals().refreshToken,
      );

      ApiRepository().setToken(Globals().token);

      try {
        await VnuCore().addFirebaseToken(firebaseToken);
      } catch (e) {
        logError('addFirebaseToken lỗi: ${e.toString()}');
      }

      if (!mounted) return;

      _goToMain();
    } catch (e) {
      logError('Refresh token lỗi: ${e.toString()}');

      await _clearLoginSession();

      if (!mounted) return;

      _goToAdmission();
    }
  }

  Future<void> _clearLoginSession() async {
    try {
      Globals().clearSession();

      await DataRepository().saveSecureKey(kLoginToken, '');
      await DataRepository().saveSecureKey(kLoginRefreshToken, '');

      ApiRepository().setToken('');
    } catch (e) {
      logError('Clear session lỗi: ${e.toString()}');
    }
  }

  void _goToAdmission() {
    if (_hasNavigated || !mounted) return;

    _hasNavigated = true;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const VcoreAdmissionView(),
      ),
          (route) => false,
    );
  }

  void _goToMain() {
    if (_hasNavigated || !mounted) return;

    _hasNavigated = true;

    if (VnuCore().loginSucces != null) {
      VnuCore().loginSucces!(Globals().token);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => widget.mainScreen,
      ),
          (route) => false,
    );
  }

  Future<void> _subscribeTopics(List<String> topics) async {
    ServicesUrl().topics = topics;

    await Future.forEach(topics, (topic) async {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic.toString());
    });

    await Future.forEach(topics, (topic) async {
      await FirebaseMessaging.instance.subscribeToTopic(topic.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: 36,
            bottom: 40,
            left: 30,
            right: 30,
          ),
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