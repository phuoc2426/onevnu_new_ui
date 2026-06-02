import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes/app_theme.dart';
import '../widgets/buttons_widget.dart';
import '../extensions/color_ext.dart';
import 'app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

snackBarError(String? message) {
  if (message !=
          'Không có kết nối Internet. Vui lòng kiểm tra lại kết nối Internet.' &&
      message?.isNotEmpty == true) {
    Get.snackbar('Lỗi', message!,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: AppTheme.colorError);
  }
}

snackBarWarning(String? message) {
  Get.snackbar('Thông báo', message ?? '',
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      backgroundColor: AppTheme.colorWarning);
}

snackBarSuccess(String? message) {
  Get.snackbar('Thông báo', message ?? '',
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      backgroundColor: AppTheme.colorSuccess);
}

Image imageAsset(String name,
    {double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
    String package = 'vnu_core'}) {
  return Image.asset(
    name,
    package: package,
    width: width,
    height: height,
    fit: fit,
    color: color,
  );
}

SvgPicture svgAsset(String name,
    {double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
    String package = 'vnu_core'}) {
  return SvgPicture.asset(
    name,
    package: package,
    width: width,
    height: height,
    colorFilter: color?.toColorFilter,
    fit: fit,
  );
}

Widget svgAction(String name,
    {double? width,
    double? height,
    Color? color,
    Function()? action,
    BoxFit fit = BoxFit.contain,
    String package = 'vnu_core'}) {
  return IconButton(
      constraints: const BoxConstraints(),
      onPressed: action,
      icon: svgAsset(name,
          width: width,
          height: height,
          color: color,
          package: package,
          fit: fit));
}

class Utils {
  static Offset locationOffSetView(GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset;
  }

  static RenderBox? locationRenderBoxView(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    return renderBox;
  }

  static Future<String> version() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  // static Future<String?> browerAgent() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
  //   logSuccess(
  //       'Running on ${webBrowserInfo.userAgent}'); // e.g. "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0"
  //   return webBrowserInfo.userAgent;
  // }

  // static Future<String?> deviceId() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  //   if (Platform.isIOS) {
  //     // import 'dart:io'
  //     var iosDeviceInfo = await deviceInfo.iosInfo;
  //     return iosDeviceInfo.identifierForVendor; // unique ID on iOS
  //   } else if (Platform.isAndroid) {
  //     var androidDeviceInfo = await deviceInfo.androidInfo;
  //     // return androidDeviceInfo.androidId; // unique ID on Android
  //   }
  //   return '';
  // }

  static Future<bool> openUrl(String? url) async {
    if (url == null) return false;
    Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      return false;
    }
    return true;
  }

  static hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Show diolog
  static showAlertDialog(BuildContext? context, String titleStr, String? desStr,
      {String? cancelStr,
      String? okStr,
      bool? withoutBinding,
      Function? callBackCancel,
      Function? callBackOK}) {
    late BuildContext contextDialog;

    Widget? cancelButton;
    if (cancelStr != null && cancelStr != "") {
      cancelButton = WhiteButton(
        width: 100,
        title: cancelStr,
        action: () {
          Navigator.pop(contextDialog);
          if (callBackCancel != null) {
            callBackCancel();
          }
        },
      );
    }

    Widget? okButton;
    if (okStr != null && okStr != "") {
      okButton = BlueButton(
        width: 100,
        title: okStr,
        bgColor: AppColors.greenAccent,
        action: () {
          Navigator.pop(contextDialog);
          if (callBackOK != null) {
            callBackOK();
          }
        },
      );
    }
    final VcoreCustomDialog alert = VcoreCustomDialog(
      title: titleStr,
      content: desStr ?? '',
      actions: [
        if (cancelStr != null && cancelStr != "") ...[
          cancelButton!,
        ],
        if (okStr != null && okStr != "") ...[
          okButton!,
        ]
      ],
    );
    if (withoutBinding == true) {
      showDialog(
        context: context!,
        builder: (BuildContext context) {
          contextDialog = context;
          return alert;
        },
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // show the dialog
      showDialog(
        context: context!,
        builder: (BuildContext context) {
          contextDialog = context;
          return alert;
        },
      );
    });
  }

  static showGetAlertDialog(String titleStr, String? desStr,
      {String? cancelStr,
      String? okStr,
      bool? withoutBinding,
      Function? callBackCancel,
      Function? callBackOK}) {
    Widget? cancelButton;
    if (cancelStr != null && cancelStr != "") {
      cancelButton = WhiteButton(
        width: 100,
        title: cancelStr,
        action: () {
          Get.back();
          if (callBackCancel != null) {
            callBackCancel();
          }
        },
      );
    }

    Widget? okButton;
    if (okStr != null && okStr != "") {
      okButton = BlueButton(
        width: 100,
        title: okStr,
        bgColor: AppColors.greenAccent,
        action: () {
          Get.back();
          if (callBackOK != null) {
            callBackOK();
          }
        },
      );
    }
    final VcoreCustomDialog alert = VcoreCustomDialog(
      title: titleStr,
      content: desStr ?? '',
      actions: [
        if (cancelStr != null && cancelStr != "") ...[
          cancelButton!,
        ],
        if (okStr != null && okStr != "") ...[
          okButton!,
        ]
      ],
    );

    Get.dialog(alert);
  }

  static showProgress(BuildContext? context,
      {String? strContent, bool? withoutBinding}) {
    if (context == null) return;
    if (withoutBinding == true) {
      final progress = ProgressHUD.of(context);
      if (strContent != null) {
        progress?.showWithText(strContent);
      } else {
        progress?.show();
      }

      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = ProgressHUD.of(context);
      if (strContent != null) {
        progress?.showWithText(strContent);
      } else {
        progress?.show();
      }
    });
  }

  static dismissProgress(BuildContext? context) {
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = ProgressHUD.of(context);
      progress?.dismiss();
    });
  }
}

class VcoreCustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;

  const VcoreCustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSizes.extraLarge,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111B3D),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              content,
              style: const TextStyle(
                fontSize: AppFontSizes.font14_5,
                color: Colors.black87,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: action,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
