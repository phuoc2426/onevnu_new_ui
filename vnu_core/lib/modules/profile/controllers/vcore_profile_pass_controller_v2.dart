import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/vnu_core.dart';

class VcoreProfilePassControllerV2 extends GetxController {
  BuildContext? context;

  RxBool isLoading = false.obs;
  RxBool forgotSent = false.obs;

  RxList<LoaiMatKhauModel> listLoaiMatKhau = RxList([]);
  Rxn<LoaiMatKhauModel> changeLoaiMatKhau = Rxn();
  Rxn<LoaiMatKhauModel> forgotLoaiMatKhau = Rxn();

  String oldPassword = '';
  String newPassword = '';
  String reNewPassword = '';

  @override
  void onInit() {
    super.onInit();
    fetchPasswordType();
  }

  Future<void> fetchPasswordType() async {
    try {
      final response = await ApiRepository().getDanhSachLoaiMatKhau();
      listLoaiMatKhau.value = response;

      final defaultType = listLoaiMatKhau.firstWhereOrNull(
        (item) => item.key == 'Default',
      );

      if (defaultType != null) {
        changeLoaiMatKhau.value = defaultType;
        forgotLoaiMatKhau.value = defaultType;
        return;
      }

      if (listLoaiMatKhau.isNotEmpty) {
        changeLoaiMatKhau.value = listLoaiMatKhau.first;
        forgotLoaiMatKhau.value = listLoaiMatKhau.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  String labelOf(LoaiMatKhauModel? type) {
    final key = type?.key ?? '';
    final label = type?.label?.trim() ?? '';

    if (key == 'Default') return 'Email VNU';
    if (key == 'DaoTao') return 'Đào tạo';
    return label.isNotEmpty ? label : 'Loại mật khẩu';
  }

  bool isEmailVnu(LoaiMatKhauModel? type) {
    final key = type?.key ?? '';
    final label = type?.label?.toLowerCase() ?? '';

    return key == 'Default' || label.contains('email') || label.contains('vnu');
  }

  Future<bool> quenMatKhau() async {
    if (forgotLoaiMatKhau.value == null) {
      snackBarWarning('Vui lòng chọn loại mật khẩu cần lấy lại.');
      return false;
    }

    try {
      Utils.showProgress(context);
      await ApiRepository().putQuenMatKhau(forgotLoaiMatKhau.value?.key ?? '');
      Utils.dismissProgress(context);

      forgotSent.value = true;
      snackBarSuccess(_forgotSuccessMessage(forgotLoaiMatKhau.value));
      return true;
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
      return false;
    }
  }

  Future<bool> thayDoiMatKhau() async {
    if (changeLoaiMatKhau.value == null) {
      snackBarWarning('Vui lòng chọn loại mật khẩu.');
      return false;
    }

    if (oldPassword.isEmpty || newPassword.isEmpty || reNewPassword.isEmpty) {
      snackBarWarning('Các trường thông tin không được để trống.');
      return false;
    }

    if (newPassword != reNewPassword) {
      snackBarWarning('Mật khẩu mới không trùng nhau.');
      return false;
    }

    try {
      Utils.showProgress(context);
      await ApiRepository().putCapNhatMatKhau(
        changeLoaiMatKhau.value?.key ?? '',
        oldPassword,
        newPassword,
      );
      Utils.dismissProgress(context);

      snackBarSuccess(_changeSuccessMessage(changeLoaiMatKhau.value));

      Future.delayed(const Duration(seconds: 2), () {
        Globals().clearSession();
        VnuCore().gotoLogin();
      });

      return true;
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
      return false;
    }
  }

  String _changeSuccessMessage(LoaiMatKhauModel? type) {
    if (isEmailVnu(type)) {
      return 'Đổi mật khẩu Email VNU thành công. Thông báo sẽ được gửi về email khôi phục tài khoản được cấu hình trên IDP.';
    }

    return 'Đổi mật khẩu ${labelOf(type)} thành công. Vui lòng đăng nhập lại bằng mật khẩu mới.';
  }

  String _forgotSuccessMessage(LoaiMatKhauModel? type) {
    if (isEmailVnu(type)) {
      return 'Yêu cầu lấy lại mật khẩu đã được gửi. Thông báo sẽ được gửi về email khôi phục tài khoản được cấu hình trên IDP.';
    }

    return 'Yêu cầu lấy lại mật khẩu ${labelOf(type)} đã được gửi.';
  }
}
