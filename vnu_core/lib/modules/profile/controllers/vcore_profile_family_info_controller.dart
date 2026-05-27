import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/student_info_model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreProfileFamilyInfoController extends GetxController {
  BuildContext? context;

  Rx<StudentInfoModel> sinvienEdit = StudentInfoModel().obs;

  bool configValueOk = false;

  @override
  void onInit() {
    super.onInit();
    if (Globals().thongTinSinhVienModel.value != null) {
      configValueOk = true;
      configWithSinhVienModel(Globals().thongTinSinhVienModel.value!);
    }
  }

  configWithSinhVienModel(StudentInfoModel sinhvien) {
    //
    sinvienEdit.value = StudentInfoModel(
      thanhPhanGiaDinh: sinhvien.thanhPhanGiaDinh,
      // -- Cha
      hoVaTenCha: sinhvien.hoVaTenCha,
      ngaySinhCha: sinhvien.ngaySinhCha,
      dienThoaiCha: sinhvien.dienThoaiCha,
      ngheNghiepCha: sinhvien.ngheNghiepCha,
      emailCha: sinhvien.emailCha,
      diaChiCha: sinhvien.diaChiCha,
      nguyenQuanCha: sinhvien.nguyenQuanCha,
      diaChiCoQuanCha: sinhvien.diaChiCoQuanCha,
      // -- Me
      hoVaTenMe: sinhvien.hoVaTenMe,
      ngaySinhMe: sinhvien.ngaySinhMe,
      dienThoaiMe: sinhvien.dienThoaiMe,
      ngheNghiepMe: sinhvien.ngheNghiepMe,
      emailMe: sinhvien.emailMe,
      diaChiMe: sinhvien.diaChiMe,
      nguyenQuanMe: sinhvien.nguyenQuanMe,
      diaChiCoQuanMe: sinhvien.diaChiCoQuanMe,

      // - Vo - chong
      hoVaTenVoChong: sinhvien.hoVaTenVoChong,
      ngaySinhVoChong: sinhvien.ngaySinhVoChong,
      ngheNghiepVoChong: sinhvien.ngheNghiepVoChong,
      diaChiVoChong: sinhvien.diaChiVoChong,

      // Anh Em
      anhEm: sinhvien.anhEm,
      ngaySinhAnhEm: sinhvien.ngaySinhAnhEm,
      ngheNghiepAnhEm: sinhvien.ngheNghiepAnhEm,

      // Con
      conCai: sinhvien.conCai,
    );
  }

  updateFamilyInfo() async {
    //
    if (!configValueOk) {
      snackBarWarning('Không tìm thấy thông tin sinh viên');
      return;
    }
    Utils.showProgress(context);
    try {
      var response =
          await ApiRepository().updateSinhVienInfo(sinvienEdit.value);

      Globals().refreshStudentInfo();

      Utils.dismissProgress(context);
      Get.back(closeOverlays: true);
      snackBarSuccess('Cập nhật thông tin thành công.');
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }
}
