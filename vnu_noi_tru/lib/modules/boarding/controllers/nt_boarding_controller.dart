import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/repository/noitru_dormitory_repository.dart';

class NtBoardingController extends GetxController {
  BuildContext? context;

  RxList<PhieuDangKyNoiTruModel> phieuDangKy = RxList([]);

  @override
  void onInit() {
    super.onInit();
    getDanhSachPhieuDangKy();
  }

  @override
  void onClose() {
    super.onClose();
  }

  getDanhSachPhieuDangKy() async {
    String cmndCccd = await VnuCore().getLoginUserName() ?? '';
    logSuccess(cmndCccd);
    //TODO: - fix cccd
    // if (kDebugMode) {
    //   cmndCccd = '030303001240';
    // }
    Utils.showProgress(context);
    try {
      var response =
          await NoitruDormitoryRepository().getDanhSachPhieuDangKy(cmndCccd);
      if (response.resultCode == 0) {
        logSuccess('Get Phieu dang ky thành công');
        response.data.phieuDangKy ?? [];

        Utils.dismissProgress(context);
      } else {
        Utils.dismissProgress(context);
        logError(response.resultMessage ?? '');
        snackBarError(response.resultMessage);
      }
    } catch (e) {
      Utils.dismissProgress(context);
    }
  }
}
