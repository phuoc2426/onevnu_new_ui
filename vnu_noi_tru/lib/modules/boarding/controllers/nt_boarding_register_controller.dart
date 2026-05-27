import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/repository/noitru_dormitory_repository.dart';

class NtBoardingRegisterController extends GetxController {
  BuildContext? context;

  RxList<DanhSachDoiTuongUuTien> danhSachDoiTuongUuTien = RxList([]);

  RxList<DanhSachDotDangKyLuuTru> danhSachDotDangKyLuuTru = RxList([]);

  RxList<DanhSachTrungTamLuuTru> danhSachTrungTamLuuTru = RxList([]);

  // Danh sách loại phòng. thuộc từng trung tâm lưu trú khác nhau
  RxList<DanhSachLoaiPhong> danhSachLoaiPhong = RxList([]);

  // Value đã chọn
  Rxn<DanhSachDoiTuongUuTien> doiTuongUuTien = Rxn();
  Rxn<DanhSachDotDangKyLuuTru> dotDangKyLuuTru = Rxn();
  Rxn<DanhSachTrungTamLuuTru> trungTamLuuTru = Rxn();
  Rxn<DanhSachLoaiPhong> loaiPhong = Rxn();

  RxList<NtFileMinhChungModel> fileMinhChung = RxList([]);

  @override
  void onInit() {
    super.onInit();
    getDanhSachDoiTuongUuTien();
    getDanhSachDotDangKy();
    getDanhSachTrungTamLuuTru();
  }

  @override
  void onClose() {
    super.onClose();
  }

  getDanhSachDoiTuongUuTien() async {
    try {
      Utils.showProgress(context);
      var response =
          await NoitruDormitoryRepository().getDanhSachDoiTuongUuTien();
      danhSachDoiTuongUuTien.value = response.data.danhSachDoiTuongUuTien ?? [];

      Utils.dismissProgress(context);
    } on DioException catch (e) {
      Utils.dismissProgress(context);

      logError(e.toString());
      snackBarError(e.toString());
    } catch (e) {
      Utils.dismissProgress(context);

      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getDanhSachDotDangKy() async {
    try {
      var response = await NoitruDormitoryRepository().getDanhSachDotDangKy();
      danhSachDotDangKyLuuTru.value =
          response.data.danhSachDotDangKyLuuTru ?? [];
    } on DioException catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    } catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  /// Danh sách ký túc xá
  getDanhSachTrungTamLuuTru() async {
    try {
      var response =
          await NoitruDormitoryRepository().getDanhSachTrungTamLuuTru();
      trungTamLuuTru.value = response.data.danhSachTrungTamLuuTru?.first;
      danhSachTrungTamLuuTru.value = response.data.danhSachTrungTamLuuTru ?? [];
    } on DioException catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    } catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getDanhSachPhongCuaTrungTam(int ID_TrungTamLuuTru) async {
    //Reset
    danhSachLoaiPhong.value = [];
    loaiPhong.value = null;

    try {
      Utils.showProgress(context);
      var response =
          await NoitruDormitoryRepository().getDanhSachPhong(ID_TrungTamLuuTru);
      danhSachLoaiPhong.value = response.data.danhSachLoaiPhong ?? [];

      Utils.dismissProgress(context);
    } on DioException catch (e) {
      Utils.dismissProgress(context);
      logError(e.toString());
      snackBarError(e.toString());
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
      logError(e.toString());
    }
  }

  // dangKyNoitru(
  //     List<DanhSachDoiTuongUuTien>? doiTuongUuTien,
  //     DanhSachDotDangKyLuuTru dotDangKyLuuTru,
  //     DanhSachTrungTamLuuTru trungTamLuuTru,
  //     DanhSachLoaiPhong loaiPhong,
  //     List<int> fileIds) async {
  //   String cmndCccd = await VnuCore().getLoginUserName() ?? '';
  //   logSuccess(cmndCccd);
  //   //TODO: - fix cccd
  //   // if (kDebugMode) {
  //   //   cmndCccd = '092014158';
  //   // }
  //   LuuNoiTruRequest request = LuuNoiTruRequest(
  //       cmndCccd: cmndCccd,
  //       idDoiTuongUuTien: doiTuongUuTien != null
  //           ? doiTuongUuTien
  //               .where((element) {
  //                 return (element.id != null);
  //               })
  //               .map((e) => e.id!)
  //               .toList()
  //           : [],
  //       idDotDangKy: dotDangKyLuuTru.id ?? -1,
  //       idTrungTamLuuTru: trungTamLuuTru.id ?? -1,
  //       idLoaiPhong: loaiPhong.id ?? -1,
  //       filesDinhKem: fileIds,
  //       trangThai: 1);
  //   emit(NtRegisterShowHub());
  //   try {
  //     var response =
  //         await NoitruDormitoryRepository().luuThongTinDangKy(request);
  //     // emit(NtRegisterLoadedListDanhSachDotDangKy(response.data));
  //     emit(NtRegisterDismissHub());
  //     if (response.resultCode == 0) {
  //       emit(
  //           NtRegisterSavedSuccess('Gửi thông tin đăng ký nội trú thành công'));
  //     } else {
  //       emit(NtRegisterLoadedError(response.resultMessage ?? kMessageError));
  //     }
  //   } on DioException catch (e) {
  //     logError(e.response.toString());
  //     emit(NtRegisterDismissHub());
  //     emit(NtRegisterLoadedError(e.toString()));
  //   } catch (e) {
  //     logError(e.toString());
  //     emit(NtRegisterDismissHub());
  //     emit(NtRegisterLoadedError(e.toString()));
  //   }
  // }

  //Selected
  selectedDoiTuongUuTien(String? name) {
    DanhSachDoiTuongUuTien? obj = danhSachDoiTuongUuTien.firstWhereOrNull(
        (element) => element.tenDoiTuongUuTien == (name ?? "_///_"));
    if (obj != null) {
      doiTuongUuTien.value = obj;
    }
  }

  selectedDotDangKy(String? name) {
    DanhSachDotDangKyLuuTru? obj = danhSachDotDangKyLuuTru.firstWhereOrNull(
        (element) => element.tenDotDangKy == (name ?? "_///_"));
    if (obj != null) {
      dotDangKyLuuTru.value = obj;
    }
  }

  selectedKyTucXa(String? name) {
    DanhSachTrungTamLuuTru? obj = danhSachTrungTamLuuTru.firstWhereOrNull(
        (element) => element.tenTrungTamLuuTru == (name ?? "_///_"));
    if (obj != null) {
      trungTamLuuTru.value = obj;
      if (obj.id != null) {
        getDanhSachPhongCuaTrungTam(obj.id!);
      }
    }
  }

  selectedLoaiPhong(String? name) {
    DanhSachLoaiPhong? obj = danhSachLoaiPhong.firstWhereOrNull(
        (element) => element.tenLoaiPhong == (name ?? "_///_"));
    if (obj != null) {
      loaiPhong.value = obj;
    }
  }
}
