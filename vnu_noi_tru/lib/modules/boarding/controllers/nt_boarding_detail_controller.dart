import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vnu_noi_tru/models/noi_tru_phieu_dang_ky_model.dart';
import 'package:vnu_noi_tru/models/nt_danh_sach_phong_model.dart';

class NtBoardingDetailController extends GetxController {
  BuildContext? context;

  PhieuDangKyNoiTruModel? phieuDangKyNoiTruModel;
  Rxn<DanhSachLoaiPhong> loaiPhong = Rxn();
}
