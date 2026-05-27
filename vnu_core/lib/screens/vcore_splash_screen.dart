import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/models/current_user_model.dart';
import 'package:vnu_core/models/student_info_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/screens/vcore_login_screen_v3.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';

import '../globals.dart';

class VCoreSplashScreen extends StatefulWidget {
  final Widget mainScreen;

  const VCoreSplashScreen({Key? key, required this.mainScreen})
      : super(key: key);

  @override
  State<VCoreSplashScreen> createState() => _VCoreSplashScreenState();
}

class _VCoreSplashScreenState extends State<VCoreSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 0), () async {
      try {
        initializeDateFormatting().then((_) {});
      } catch (e) {
        logError(e.toString());
      }

      String token = '';
      String refreshToken = '';
      String? firebaseToken;

      try {
        firebaseToken = await FirebaseMessaging.instance.getToken();
        logError("FCM token"+firebaseToken.toString());
      } catch (e) {
        logError("FCM lỗi"+e.toString());
      }
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

      if (token.isEmpty) {
        await VnuCore().addFirebaseToken(firebaseToken);

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (ctx) => const VCoreLoginScreenV3()),
            (route) => false);
      } else if (VnuCore().loginSucces != null) {
        // refresh token
        Globals().token = token;
        Globals().refreshToken = refreshToken;
        _refreshAndLoadUserInfo(firebaseToken);
      }
    });
  }

  T? cast<T>(x) => x is T ? x : null;

  _refreshAndLoadUserInfo(String? firebaseToken) async {
    //get current user
    try {
      var responseRefreshToken =
          await ApiRepository().refreshToken(Globals().refreshToken);
      Globals().token = responseRefreshToken.accessToken ?? '';
      Globals().refreshToken = responseRefreshToken.refreshToken ?? '';

      DataRepository().saveSecureKey(kLoginToken, Globals().token);
      DataRepository()
          .saveSecureKey(kLoginRefreshToken, Globals().refreshToken);

      ApiRepository().setToken(Globals().token);

      await VnuCore().addFirebaseToken(firebaseToken);

      if (VnuCore().loginSucces != null) {
        VnuCore().loginSucces!(Globals().token);
      }
    } catch (e) {
      logError(e.toString());
      Globals().clearSession();

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (ctx) => const VCoreLoginScreenV3()),
          (route) => false);
    }
  }

  _subscribeTopics(List<String> topics) async {
    ServicesUrl().topics = topics;

    await Future.forEach(topics, (topic) async {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    });

    await Future.forEach(topics, (topic) async {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          margin:
              const EdgeInsets.only(top: 36, bottom: 40, left: 30, right: 30),
          child: Image.asset(
            'assets/images/ic_logo_vnu_full.png',
            package: 'vnu_noi_tru',
          ),
        ),
      ),
    );
  }
}
