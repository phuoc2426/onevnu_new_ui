import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/tong_ket_den_hien_tai_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';

import '../views/widget/vcore_profile_textfield_widget.dart';

class VcoreProfileController extends GetxController {
  RxBool isDeviceSupportBio = false.obs;
  RxBool isBioByFaceId = true.obs;

  Rxn<TongKetDenHienTaiModel> tongket = Rxn();

  //For open debug log
  final int serialTaps = 10;
  final int tapDurationInMs = 7000;

  int get timeNow => DateTime.now().millisecondsSinceEpoch;
  var startTap = DateTime.now().millisecondsSinceEpoch;

  int consecutiveTaps = 0;

  @override
  void onInit() {
    super.onInit();
  }

  getTongKetDenHienTai() async {
    try {
      var response = await ApiRepository().getTongKetDenHienTai();
      if (response.isNotEmpty) {
        tongket.value = response.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  countVersionOpenLog(BuildContext context) {
    if (kDebugMode) {
      Get.to(
        () => TalkerScreen(talker: Globals().talker),
      );
    }
    final now = timeNow;
    final userExceededTapDuration = now - startTap > tapDurationInMs;

    if (userExceededTapDuration) {
      consecutiveTaps = 0;
      startTap = now;
    }

    consecutiveTaps++;

    if (consecutiveTaps == serialTaps) {
      // OK
      var password = "";
      final buttonWidth = MediaQuery.of(context).size.width / 4;
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.center,
              contentPadding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 30.0),
              buttonPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 40.0, 30.0),
              content: VcoreProfileTextFieldWidget(
                title: 'Mật khẩu',
                hintText: 'Nhập mật khẩu',
                value: password,
                autoFocus: true,
                onChange: (text) {
                  password = text;
                },
                onSubmitted: (text) {
                  password = text;
                },
              ),
              actions: [
                WhiteButton(
                  width: buttonWidth,
                  title: "Hủy",
                  action: () {
                    Navigator.pop(context);
                  },
                ),
                BlueButton(
                  width: buttonWidth,
                  title: "Xác nhận",
                  action: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          }).then(
        (v) async {
          if (password.isEmpty) {
            return;
          }
          if (password == kLogPass) {
            Get.to(
              () => TalkerScreen(talker: Globals().talker),
            );
          } else {
            snackBarError('Mật khẩu không đúng.');
          }
          //
        },
      );
    }
  }
}
