import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../models/model.dart';

class VcoreStudentCardController extends GetxController {
  // Hoặc StatefulWidget
  BuildContext? context;

  Map<String, dynamic> thongTinSinhVien = {
    'tenDonVi': '',
    'iconDonVi': '',
    'hoTen': '',
    'maSV': '',
    'ngaySinh': '',
    'khoaHoc': '',
    'khoa': '',
    'GT': '',
    'He': '',
    'HSD': '',
    'chuongTrinhDaoTao': '',
    'nganhHoc': '',

  };
  bool isLoading = true;
  static const double perspective = 0.0015;
  static const double aspect = 22 / 15;

  final TransformationController transform = TransformationController();

  /// Góc lật hiện tại (radian): 0 -> π
  final RxDouble angle = 0.0.obs;

  /// Đang ở mặt sau?
  bool get isBack => isBackFrom(angle.value);

  bool isBackFrom(double a) {
    final norm = a % (2 * math.pi);
    return norm > math.pi / 2 && norm < 3 * math.pi / 2;
  }


  void setAngle(double v) {
    angle.value = v;
    update();
  }

  Matrix4 matrixFor(double angleY) =>
      Matrix4.identity()..setEntry(3, 2, perspective)..rotateY(angleY);

  /// Animate đưa zoom về identity (nhận vsync từ View)
  Future<void> recenter(TickerProvider vsync) async {
    final begin = transform.value.clone();
    final end = Matrix4.identity();
    final ctrl = AnimationController(
        vsync: vsync, duration: const Duration(milliseconds: 300));
    final tween = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
    );
    ctrl.addListener(() => transform.value = tween.value);
    await ctrl.forward();
    ctrl.dispose();
  }

  @override
  void onInit() {
    super.onInit();
    getUserData();
  }

  getUserData() async {
    try {
      //Tên đơn vị - Id guild - Id guild đơn vị
      var currentUser = await ApiRepository().getCurrentUser();
      String guildDonVi = currentUser?.guidDonVi ?? "";
      String guild = currentUser?.guid ?? "";

      //Họ tên - Ngày sinh - Giới tính - Id hệ đào tạo - Id bậc đào tạo
      var studentInfo = await ApiRepository().getSinhVienInfo();
      thongTinSinhVien["hoTen"] = studentInfo?.hoVaTen ?? "";

      final rawNgaySinh = studentInfo?.ngaySinh;
      if (rawNgaySinh == null) {
        thongTinSinhVien["ngaySinh"] = "";
      } else {
        final s = rawNgaySinh.toString().trim();
        if (s.isEmpty) {
          thongTinSinhVien["ngaySinh"] = "";
        } else {
          try {
            final dt = DateTime.parse(s); // nếu không đúng ISO thì đổi sang DateFormat.parse phù hợp
            thongTinSinhVien["ngaySinh"] = DateFormat('dd/MM/yyyy').format(dt);
          } catch (_) {
            // Không parse được thì để rỗng, tránh nổ
            thongTinSinhVien["ngaySinh"] = "";
          }
        }
      }

      thongTinSinhVien["GT"] = studentInfo?.gioiTinh.toString() ?? "";
      thongTinSinhVien["maSV"] = studentInfo?.maSinhVien.toString() ?? "";

      await loadDataNhapHoc();
      update();
      isLoading = false;
    } catch (e) {
      isLoading = false;
      logError(e.toString());
    }
  }

  loadDataNhapHoc() async {
    thongTinSinhVien["khoaHoc"] = Globals().lopDaoTaoModel.value?.ten ?? '';

    try {
      var response = await ApiRepository().getDataChuongTrinhDaoTao(
          Globals().thongTinSinhVienModel.value?.idChuongTrinhDaoTao,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          Globals().thongTinSinhVienModel.value?.idBacDaoTao,
          Globals().thongTinSinhVienModel.value?.idHeDaoTao,
          Globals().thongTinSinhVienModel.value?.idNganhDaoTao,
          Globals().thongTinSinhVienModel.value?.idNienKhoaDaoTao);
      if (response.isNotEmpty) {
        thongTinSinhVien["khoa"] = response.first.ten ?? '';
      }
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataHeDaoTao(
        Globals().thongTinSinhVienModel.value?.idHeDaoTao,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        Globals().thongTinSinhVienModel.value?.idBacDaoTao,
      );
      if (response.isNotEmpty) {
        thongTinSinhVien["He"] = response.first.ten ?? '';
      }
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDonVi(
        Globals().currentUserModel.value?.guidDonVi ?? '',
      );
      thongTinSinhVien["tenDonVi"] = response.tenDonVi ?? '';
    } catch (e) {
      logError(e.toString());
    }

    if ((Globals().thongTinSinhVienModel.value?.idNganhDaoTao ?? '')
        .isNotEmpty) {
      try {
        var response = await ApiRepository().getDataNganhDaoTao(
            Globals().thongTinSinhVienModel.value?.idNganhDaoTao,
            Globals().currentUserModel.value?.guidDonVi ?? '',
            Globals().thongTinSinhVienModel.value?.idBacDaoTao);
        if (response.isNotEmpty) {
          thongTinSinhVien["nganhHoc"] = response.first.ten ?? '';
        }
      } catch (e) {
        logError(e.toString());
      }
    }
    update(); // Cập nhật lại UI

  }

// @override
// void onClose() {
//   transform.dispose();
//   super.onClose();
// }
}
