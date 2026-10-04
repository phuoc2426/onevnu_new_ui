import 'dart:async';
import 'dart:io';

import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bloc/bloc.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/login_reponse_model.dart';
import 'package:vnu_core/modules/auth_mode/auth_entry_mode_service.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';

import '../vnu_core.dart';

import 'package:shared_preferences/shared_preferences.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  login(String username, String passsword) async {
    if (username.isEmpty || passsword.isEmpty) {
      emit(AuthError('Thông tin đăng nhập không được để trống'));
      return;
    }
    emit(AuthShowHub());
    try {
      snackBarError('Not use function, deprecate use new api signup');
      // var reponse = await ApiRepository()
      //     .login(username, passsword, 'tokenDevice', 'thongtinthietbi');
      // if (reponse.errorCode == 200 && reponse.data != null) {
      //   //save login info
      //   DataRepository().saveSecureUserLogin(username, passsword);

      //   //save token
      //   Globals().token = reponse.data ?? '';
      //   ApiRepository().setToken(Globals().token);
      //   DataRepository().saveSecureKey(kLoginToken, Globals().token);

      //   //get user info
      //   var responseUser = await ApiDormitoryRepository().getUserInfo(username);
      //   if (responseUser.resultCode == 0) {
      //     Globals().thongTinSinhVienModel = responseUser.data;
      //   }
      //   emit(AuthDismissHub());
      //   //emit(AuthSuccess(reponse));
      //   if (VnuCore().loginSucces != null) {
      //     VnuCore().loginSucces!(Globals().token);
      //   }
      // } else {
      //   emit(AuthDismissHub());
      //   emit(AuthError(reponse.message ?? ''));
      // }
    } catch (e) {
      emit(AuthDismissHub());
      emit(AuthError(AppErrorMapper.map(e).userMessage));
    }
  }

  loginMobile(String username, String passsword, String tokenDevice,
      String thongtinthietbi) async {
    // VnuCacheFileManager().getCacheFile('getSinhVienInfo.json');
    // return;

    if (username.isEmpty || passsword.isEmpty) {
      emit(AuthError('Thông tin đăng nhập không được để trống'));
      return;
    }
    emit(AuthShowHub());
    try {
      logSuccess('Firebase token is available');
      //Globals().fireBaseToken
      logSuccess('Start login time --> ${DateTime.now().toIso8601String()}');
      var reponse = await ApiRepository()
          .signin(username, passsword, '');
      if (reponse.refreshToken != null) {
        // ONEVNU_STALE_STUDENT_FIX_20260725_LOGIN_CLEAR
        Globals().thongTinSinhVienModel.value = null;
        Globals().currentUserModel.value = null;
        Globals().lopDaoTaoModel.value = null;

                Globals().nienKhoaDaoTaoModel.value = null;

        final SharedPreferences prefs =
            await SharedPreferences.getInstance();

        const List<String> applicantKeys = <String>[
          'applicant_cccd',
          'applicant_fullname',
          'applicant_email',
          'applicant_dob',
          'applicant_phone',
        ];

        for (final String key in applicantKeys) {
          await prefs.remove(key);
        }

        // USER login must replace any Applicant session stored on this install.
        await Future.wait<void>(<Future<void>>[
          DataRepository().deleteSecureKey(kApplicantAccessToken),
          DataRepository().deleteSecureKey(kApplicantRefreshToken),
          DataRepository().saveSecureUserLogin(username, passsword),
        ]);

        // Save the authenticated ONEVNU session first. FCM is deliberately not
        // part of /signin and is synchronized afterwards on a best-effort path.
        Globals().token = reponse.accessToken ?? '';
        Globals().refreshToken = reponse.refreshToken ?? '';
        Globals().usernameLogin = username;

        ApiRepository().setToken(Globals().token);
        await Future.wait<void>(<Future<void>>[
          DataRepository().saveSecureKey(kLoginToken, Globals().token),
          DataRepository().saveSecureKey(
            kLoginRefreshToken,
            Globals().refreshToken,
          ),
          DataRepository().saveSecureKey(
            kSessionPrincipalType,
            kPrincipalTypeUser,
          ),
        ]);

        // Cần bỏ để tăng tốc độ login - thời gian chờ đang hơi lâu.
        // Chuyển load async ở tabbar

        
        // ONEVNU_STALE_STUDENT_FIX_20260725_LOGIN_REFRESH
        await Globals().refreshStudentInfo();

        if (Globals().thongTinSinhVienModel.value == null) {
          await Globals().clearSession();

          emit(AuthDismissHub());
          emit(
            AuthError(
              'Không tải được thông tin sinh viên '
              'của tài khoản vừa đăng nhập.',
            ),
          );
          return;
        }

        await AuthEntryModeService().markPassword();

        // Never fail a successful password login because FCM/APNs is delayed.
        unawaited(_syncFcmAfterPasswordLogin());

        emit(AuthDismissHub());

        logSuccess(
            'Start success time --> ${DateTime.now().toIso8601String()}');
        // emit(AuthSuccess(reponse));
        if (VnuCore().loginSucces != null) {
          VnuCore().loginSucces!(Globals().token);
        }
      } else {
        emit(AuthDismissHub());
        emit(AuthError(kMessageError));
      }
    } catch (e) {
      emit(AuthDismissHub());
      emit(AuthError(AppErrorMapper.map(e).userMessage));
    }
  }


  Future<void> _syncFcmAfterPasswordLogin() async {
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
        '[FCM][PASSWORD_LOGIN] post-login binding failed: '
        '$error\n$stackTrace',
      );
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

  getUserProfile() async {
    Globals().refreshStudentInfo();
  }

  doiMatKhau(String mk_cu, String mk_moi) async {
    if (mk_cu.isEmpty) {
      emit(AuthError('Thông tin Mật khẩu cũ không được để trống'));
      return;
    }
    if (mk_moi.isEmpty) {
      emit(AuthError('Thông tin Mật khẩu mới không được để trống'));
      return;
    }
    // emit(AuthShowHub());
    // try {
    //   var reponse = await ApiRepository().doiMatKhau(mk_cu, mk_moi);
    //   if (reponse.resultCode == '0') {
    //     emit(AuthDismissHub());
    //     emit(AuthMessageSucess(reponse.resultMessage ?? ''));
    //   } else {
    //     emit(AuthDismissHub());
    //     emit(AuthError(reponse.resultMessage ?? ''));
    //   }
    // } catch (e) {
    //   emit(AuthDismissHub());
    //   emit(AuthError(AppErrorMapper.map(e).userMessage));
    // }
  }
}
