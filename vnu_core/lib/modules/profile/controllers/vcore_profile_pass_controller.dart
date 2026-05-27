import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/vnu_core.dart';

class VcoreProfilePassController extends GetxController {
  BuildContext? context;

  RxBool isLoading = false.obs;
  RxList<LoaiMatKhauModel> listLoaiMatKhau = RxList([]);
  Rxn<LoaiMatKhauModel> loaiMatKhau = Rxn();

  // Doi mat khau
  String oldPassword = '';
  String newPassword = '';
  String reNewPassword = '';

  @override
  void onInit() {
    super.onInit();
    fetchPasswordType();
  }

  fetchPasswordType() async {
    //
    try {
      var response = await ApiRepository().getDanhSachLoaiMatKhau();

      listLoaiMatKhau.value = response;
      for (var item in listLoaiMatKhau) {
        if (item.key == 'Default') {
          loaiMatKhau.value = item;
        }
      }
      if (listLoaiMatKhau.isNotEmpty && loaiMatKhau.value == null) {
        loaiMatKhau.value = listLoaiMatKhau.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  quenMatKhau() async {
    if (loaiMatKhau.value == null) {
      snackBarWarning('Bạn cần chọn loại hình nhận mật khẩu');
      return;
    }
    try {
      Utils.showProgress(context);
      var reponse =
          await ApiRepository().putQuenMatKhau(loaiMatKhau.value?.key ?? '');
      Utils.dismissProgress(context);
      Get.back(closeOverlays: true);
      snackBarSuccess(
          'Mật khẩu mới đã được gửi qua ${loaiMatKhau.value?.label} cho bạn.');
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  thayDoiMatKhau() async {
    if (loaiMatKhau.value == null) {
      snackBarWarning('Bạn cần chọn loại hình nhận mật khẩu');
      return;
    }
    if (oldPassword.isEmpty || newPassword.isEmpty || reNewPassword.isEmpty) {
      snackBarWarning(
          'Các trường thông tin không được để trống và chứa khoảng trắng.');
      return;
    }
    if (newPassword != reNewPassword) {
      snackBarWarning('Mật khẩu mới không trùng nhau.');
      return;
    }
    //
    logWarning(oldPassword);
    logWarning(newPassword);
    logWarning(reNewPassword);
    //

    try {
      Utils.showProgress(context);
      var reponse = await ApiRepository().putCapNhatMatKhau(
          loaiMatKhau.value?.key ?? '', oldPassword, newPassword);
      Utils.dismissProgress(context);
      snackBarSuccess(
          'Mật khẩu của bạn đã được thay đổi thành công. Vui lòng đăng nhập lại.');
      Future.delayed(const Duration(seconds: 2), () {
        Globals().clearSession();
        VnuCore().gotoLogin();
      });
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }
}
