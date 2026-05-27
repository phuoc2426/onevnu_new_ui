import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bloc/bloc.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/login_reponse_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';

import '../vnu_core.dart';

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
      emit(AuthError('Thông tin đăng nhập không chính xác hoặc lỗi hệ thống, vui lòng liên hệ quản trị viên'));
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
      logSuccess('Firebase Token');
      logInfo(ServicesUrl().firebaseToken ?? '');
      //Globals().fireBaseToken
      logSuccess('Start login time --> ${DateTime.now().toIso8601String()}');
      var reponse = await ApiRepository()
          .signin(username, passsword, ServicesUrl().firebaseToken ?? '');
      if (reponse.refreshToken != null) {
        //save login info
        DataRepository().saveSecureUserLogin(username, passsword);

        //save token
        Globals().token = reponse.accessToken ?? '';
        Globals().usernameLogin = username;

        ApiRepository().setToken(Globals().token);
        DataRepository().saveSecureKey(kLoginToken, Globals().token);
        DataRepository()
            .saveSecureKey(kLoginRefreshToken, reponse.refreshToken ?? '');

        // Cần bỏ để tăng tốc độ login - thời gian chờ đang hơi lâu.
        // Chuyển load async ở tabbar

        emit(AuthDismissHub());

        logSuccess(
            'Start success time --> ${DateTime.now().toIso8601String()}');
        // emit(AuthSuccess(reponse));
        if (VnuCore().loginSucces != null) {
          VnuCore().loginSucces!(Globals().token);
        }
      } else {
        emit(AuthDismissHub());
        emit(AuthError('Thông tin đăng nhập không chính xác hoặc lỗi hệ thống, vui lòng liên hệ quản trị viên'));
      }
    } catch (e) {
      emit(AuthDismissHub());
      emit(AuthError('Thông tin đăng nhập không chính xác hoặc lỗi hệ thống, vui lòng liên hệ quản trị viên'));
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
    //   emit(AuthError(e.toString()));
    // }
  }
}
