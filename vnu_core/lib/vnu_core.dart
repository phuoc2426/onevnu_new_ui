// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/network_monitor.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/version_utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/browser/views/vcore_html_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_detail_view.dart';
import 'package:vnu_core/modules/question/views/vcore_question_detail_view.dart';
import 'package:vnu_core/modules/system_news/views/vcore_system_news_detail_view.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/screens/vcore_login_screen_v3.dart';
import 'package:vnu_core/screens/vcore_preview_pdf_screen.dart';
import 'package:vnu_core/screens/vcore_splash_screen.dart';
import 'package:vnu_core/services/services_url.dart';

/*
  - Quản lý đăng nhập
  - Quản lý thông tin cá nhân
  - Quản lý, đăng ký thông báo từ firebase
*/

class VnuCore {
  VnuCore._internal() {
    // Init monitor network
    NetworkMonitor().startListen();
  }

  static final VnuCore _singleton = VnuCore._internal();

  factory VnuCore() {
    return _singleton;
  }

  bool isLogin() => Globals().token.isNotEmpty;

  //Callback
  Function(String token)? loginSucces;

  runVnuApp({required Widget mainScreen}) {
    return ShadApp.custom(
      themeMode: ThemeMode.light,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadGreenColorScheme.light(),
      ),
      appBuilder: (context) {
        return GetMaterialApp(
          title: 'One VNU',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'OpenSans',
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Colors.white),
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF07964B),
              selectionColor: Color(0x3307964B),
              selectionHandleColor: Color(0xFF07964B),
            ),
          ),
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('vn'),
          navigatorKey: navigatorKey,
          home: VCoreSplashScreen(
            mainScreen: mainScreen,
          ),
        );
      },
    );
  }

  gotoLogin() {
    Navigator.pushAndRemoveUntil(
        navigatorKey.currentContext!,
        MaterialPageRoute(builder: (ctx) => const VCoreLoginScreenV3()),
        (route) => false);
  }

  gotoMainScreen(Widget screen) {
    Navigator.pushAndRemoveUntil(navigatorKey.currentContext!,
        MaterialPageRoute(builder: (ctx) => screen), (route) => false);
  }

  CurrentUserModel? getCurrentUser() {
    return Globals().currentUserModel.value;
  }

  StudentInfoModel? getStudentInfo() {
    return Globals().thongTinSinhVienModel.value;
  }

  Future<String?> getLoginUserName() async {
    return await DataRepository().getSecureSaveKey(kLoginUserName);
  }

  bool checkLoginIfNeed() {
    if (Globals().token.isNotEmpty) {
      return true;
    }
    Utils.showAlertDialog(navigatorKey.currentContext, 'Thông báo',
        'Bạn cần đăng nhập để thực hiện chức năng này.',
        cancelStr: 'Để sau', okStr: 'Đăng nhập', callBackOK: () {
      Navigator.pushAndRemoveUntil(
          navigatorKey.currentContext!,
          MaterialPageRoute(builder: (ctx) => const VCoreLoginScreenV3()),
          (route) => false);
    });
    return false;
  }

  Future<void> addFirebaseTokenSwitchDomain(String? firebaseToken) async {
    try {
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        ApiRepository()
            .deviceToken(
          '',
          firebaseToken,
          Platform.isAndroid ? 'Android' : 'iOS',
        )
            .then((result) {
          ServicesUrl().firebaseToken = firebaseToken;
          logSuccess("add token to account success...");
        }).catchError((err) {
          logError("add token to account error: $err");
        });
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> addFirebaseToken(String? firebaseToken) async {
    try {
      if (firebaseToken != null &&
          firebaseToken.isNotEmpty &&
          ServicesUrl().firebaseToken != firebaseToken) {
        ApiRepository()
            .deviceToken(
          ServicesUrl().firebaseToken ?? '',
          firebaseToken,
          Platform.isAndroid ? 'Android' : 'iOS',
        )
            .then((result) {
          ServicesUrl().firebaseToken = firebaseToken;
          logSuccess("add token to account success...");
        }).catchError((err) {
          logError("add token to account error: $err");
        });
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  void handleNotificationTapped(
      BuildContext context, Map<String, dynamic>? message) async {
    final String loaiNotification = message?['loaiNotification'] ?? '';
    final String guidItem = message?['guidItem'] ?? '';
    logSuccess('//// handle Notification VNU Core $message');

    if (guidItem.isEmpty || loaiNotification.isEmpty) {
      return;
    }

    if (loaiNotification == LoaiThongBao.CamNang.name) {
      SmartDialog.showLoading();
      try {
        final List<dynamic> results = await Future.wait([
          ApiRepository().getDetailCamNang(guidItem),
          ApiRepository().setIsRead(guidItem, loaiNotification)
        ]);
        Globals().fetchUnreadCount();
        final CamNangModel model = results.first;
        Get.to(
          () => VCorePreviewPdfScreen(
            title: model.tieuDe ?? '',
            fileId: model.guidFileCamNangs?.first ?? '',
          ),
        );
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        snackBarError(e.toString());
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.TinTuc.name) {
      SmartDialog.showLoading();
      try {
        final List<dynamic> results = await Future.wait([
          ApiRepository().getDetailTinTuc(guidItem),
          ApiRepository().setIsRead(guidItem, loaiNotification)
        ]);
        Globals().fetchUnreadCount();
        final TinTucModel response = results.first;
        SmartDialog.dismiss();

        Get.to(() => VcoreNewsDetailView(tinTucModel: response));
      } catch (e) {
        SmartDialog.dismiss();
        snackBarError(e.toString());
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.Cmsvnu_TinTuc.name) {
      SmartDialog.showLoading();
      try {
        final List<dynamic> results = await Future.wait([
          ApiRepository().getChiTietCmsTinTuc(
              guidItem, kImageCmsWidhtHeight, kImageCmsWidhtHeight),
          ApiRepository().setIsRead(guidItem, loaiNotification)
        ]);
        Globals().fetchUnreadCount();
        final TopTinTucDetailModel response = results.first;
        SmartDialog.dismiss();

        Get.to(
          () => VcoreHtmlView(
            title: response.tieuDe ?? '',
            html: response.noiDung ?? '',
          ),
        );
      } catch (e) {
        SmartDialog.dismiss();
        logError(e.toString());
        snackBarError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.TinHeThong.name) {
      SmartDialog.showLoading();
      try {
        final List<dynamic> results = await Future.wait([
          ApiRepository().getChiTietTinHeThong(guidItem),
          ApiRepository().setIsRead(guidItem, loaiNotification)
        ]);
        Globals().fetchUnreadCount();
        final TinHeThongModel response = results.first;
        Get.to(() => VcoreSystemNewsDetailView(tinTucModel: response));
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        snackBarError(e.toString());
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.CauHoi.name ||
        loaiNotification == LoaiThongBao.ChuDeCauHoi.name ||
        loaiNotification == LoaiThongBao.TraLoiCauHoi.name) {
      SmartDialog.showLoading();
      try {
        final List<dynamic> results = await Future.wait([
          ApiRepository().getDetailCauHoiDap(guidItem),
          ApiRepository().setIsRead(guidItem, loaiNotification)
        ]);
        Globals().fetchUnreadCount();
        final HoiDapModel response = results.first;
        Get.to(() => VcoreQuestionDetailView(question: response));
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        snackBarError(e.toString());
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.PhongTro.name) {
      SmartDialog.showLoading();
      try {
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        snackBarError(e.toString());
        logError(e.toString());
      }
      return;
    }
    if (loaiNotification == LoaiThongBao.HuongDanSuDung.name) {
      try {
        await ApiRepository().setIsRead(guidItem, loaiNotification);
        Globals().fetchUnreadCount();
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        logError(e.toString());
      }
      Get.to(
        () => VCorePreviewPdfScreen(
          title: message?['title'] ?? '',
          fileId: guidItem,
        ),
      );

      return;
    }

    if (loaiNotification == LoaiThongBao.TraLoiPhanAnh.name) {
      try {
        await ApiRepository().setIsRead(guidItem, loaiNotification);
        Globals().fetchUnreadCount();
      } catch (e) {
        logError(e.toString());
      }

      if (guidItem.isEmpty) {
        snackBarWarning('Không tồn tại phản ánh hiện trường với guid.');
      } else {
        SmartDialog.showLoading();
        try {
          var phanAnhHienTruongModel = await ApiRepository().getPaht(guidItem);
          SmartDialog.dismiss();
          Get.to(() => VcorePahtDetailView(
              phanAnhHienTruongModel: phanAnhHienTruongModel,
              isChuaXuLy: false));
        } catch (e) {
          SmartDialog.dismiss();
          logError(e.toString());
          snackBarError(e.toString());
        }
      }
    }

    if (loaiNotification == LoaiThongBao.ThuTucHanhChinh.name) {
      logWarning('Not hanlde notify, undefine notify type...');
      snackBarWarning('Chưa hỗ trợ định dạng thông báo.');
      return;
    }
  }

  Future<void> checkUpdateNewVersion({
    required String foreVersion,
    required String iosVersion,
    required String iosUrl,
    required String androidVersion,
    required String androidUrl,
  }) async {
    logInfo(foreVersion);
    logInfo(androidVersion);
    logInfo(androidUrl);
    logInfo(iosUrl);
    logInfo(iosVersion);
    Future.delayed(const Duration(seconds: 1), () async {
      logSuccess('checkUpdateNewVersion');
      Map<String, dynamic> fore = jsonDecode(foreVersion);

      Version versionForeIOS = Version.parse(fore['ios']?.isNotEmpty == true
          ? (fore['ios']?.toString() ?? '1.0.0')
          : '1.0.0');

      Version versionForeAndroid = Version.parse(
          fore['android']?.isNotEmpty == true
              ? (fore['android']?.toString() ?? '1.0.0')
              : '1.0.0');

      Version versionIOS =
          Version.parse(iosVersion.isNotEmpty ? iosVersion : '1.0.0');

      Version versionAndroid =
          Version.parse(androidVersion.isNotEmpty ? androidVersion : '1.0.0');

      var version = await Utils.version();
      Version versionNow = Version.parse(version);
      Version foreRemoteVersion =
          Platform.isAndroid ? versionForeAndroid : versionForeIOS;
      Version remoteVersion = Platform.isAndroid ? versionAndroid : versionIOS;
      bool isNeedIgnore = foreRemoteVersion < versionNow;
      bool isNeedUpdate = remoteVersion > versionNow;
      if (isNeedUpdate) {
        Utils.showGetAlertDialog(
          'Thông báo',
          'OneVNU đã có phiên bản mới, bạn vui lòng cập nhật phiên bản mới để sử dụng!',
          okStr: 'Cập nhật',
          cancelStr: isNeedIgnore ? 'Để sau' : null,
          callBackOK: () async {
            //url
            launchUrl(Uri.parse(Platform.isAndroid ? androidUrl : iosUrl));
          },
        );
      }
    });
  }
}
