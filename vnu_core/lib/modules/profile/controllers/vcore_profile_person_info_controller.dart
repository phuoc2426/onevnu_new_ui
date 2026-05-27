import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcoreProfilePersonInfoController extends GetxController {
  BuildContext? context;

  Rx<StudentInfoModel> sinhvienEdit = StudentInfoModel().obs;

  RxList<QuocGiaModel> listQuocGia = RxList([]);
  RxList<TinhThanhModel> listTinhThanhPho = RxList([]);
  RxList<DanTocModel> listDanToc = RxList([]);
  RxList<TonGiaoModel> listTonGiao = RxList([]);

  RxList<KhuVucUuTienModel> listKhuVucUuTien = RxList([]);

  // Quan Huyen
  RxList<QuanHuyenModel> listQuanHuyenQueQuan = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenNoiSinh = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenThuongTru = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenNoiOHienNay = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenDiaChiLL = RxList([]);

  bool configValueOk = false;

  @override
  void onInit() {
    super.onInit();

    getDataDropdown();

    if (Globals().thongTinSinhVienModel.value != null) {
      configValueOk = true;
      configWithSinhVienModel(Globals().thongTinSinhVienModel.value!);
    }
  }

  configWithSinhVienModel(StudentInfoModel sinhvien) {
    //
    sinhvienEdit.value = StudentInfoModel(
      //email
      email: sinhvien.email,
      emailKhac: sinhvien.emailKhac,

      //Bacsic
      tenKhac: sinhvien.tenKhac,

      idQuocGia: sinhvien.idQuocGia,
      idDanToc: sinhvien.idDanToc,

      idTonGiao: sinhvien.idTonGiao,
      nhomMau: sinhvien.nhomMau,

      canNang: sinhvien.canNang,
      chieuCao: sinhvien.chieuCao,

      // soCmtCccd: sinhvien.soCmtCccd,
      // ngayCapCmtCccd: sinhvien.ngayCapCmtCccd,
      // idNoiCapCmtCccdTinhThanhPho: sinhvien.idNoiCapCmtCccdTinhThanhPho,

      idDoiTuongUuTien: sinhvien.idDoiTuongUuTien,

      nangKhieu: sinhvien.nangKhieu,

      //Que quan
      idQueQuanQuocGia: sinhvien.idQueQuanQuocGia,
      idQueQuanTinhThanhPho: sinhvien.idQueQuanTinhThanhPho,
      idQueQuanQuanHuyen: sinhvien.idQueQuanQuanHuyen,
      queQuanPhuongXa: sinhvien.queQuanPhuongXa,

      // - Noi Sinh
      idNoiSinhQuocGia: sinhvien.idNoiSinhQuocGia,
      idNoiSinhQuanHuyen: sinhvien.idNoiSinhQuanHuyen,
      idNoiSinhTinhThanhPho: sinhvien.idNoiSinhTinhThanhPho,
      noiSinhPhuongXa: sinhvien.noiSinhPhuongXa,

      // - Ho khau thuong tru
      idHoKhauThuongTruTinhThanhPho: sinhvien.idHoKhauThuongTruTinhThanhPho,
      idHoKhauThuongTruQuanHuyen: sinhvien.idHoKhauThuongTruQuanHuyen,
      hoKhauThuongTruPhuongXa: sinhvien.hoKhauThuongTruPhuongXa,
      hoKhauThuongTruDuongThon: sinhvien.hoKhauThuongTruDuongThon,
      hoKhauThuongTruSoNha: sinhvien.hoKhauThuongTruSoNha,

      // - Noi o hien nay
      idNoiOHienNayQuocGia: sinhvien.idNoiOHienNayQuocGia,
      idNoiOHienNayTinhThanhPho: sinhvien.idNoiOHienNayTinhThanhPho,
      idNoiOHienNayQuanHuyen: sinhvien.idNoiOHienNayQuanHuyen,
      noiOHienNayPhuongXa: sinhvien.noiOHienNayPhuongXa,
      noiOHienNayDuongThon: sinhvien.noiOHienNayDuongThon,
      noiOHienNaySoNha: sinhvien.noiOHienNaySoNha,

      // - Dia chi lien lac
      idDiaChiLienLacQuocGia: sinhvien.idDiaChiLienLacQuocGia,
      idDiaChiLienLacTinhThanhPho: sinhvien.idDiaChiLienLacTinhThanhPho,
      idDiaChiLienLacQuanHuyen: sinhvien.idDiaChiLienLacQuanHuyen,
      diaChiLienLacPhuongXa: sinhvien.diaChiLienLacPhuongXa,
      diaChiLienLacDuongThon: sinhvien.diaChiLienLacDuongThon,
      diaChiLienLacSoNha: sinhvien.diaChiLienLacSoNha,

      //Phone
      mobile: sinhvien.mobile,
      tel: sinhvien.tel,

      // - Nhap Ngu
      isBoDoi: sinhvien.isBoDoi,
      nhapNgu: sinhvien.nhapNgu,
      xuatNgu: sinhvien.xuatNgu,

      // -- Thong tin doan
      isDoan: sinhvien.isDoan,
      noiVaoDoan: sinhvien.noiVaoDoan,
      ngayVaoDoan: sinhvien.ngayVaoDoan,
      viTriCaoNhatDoan: sinhvien.viTriCaoNhatDoan,

      // -- Thong tin dang
      isDang: sinhvien.isDang,
      ngayVaoDang: sinhvien.ngayVaoDang,
      ngayVaoDangChinhThuc: sinhvien.ngayVaoDangChinhThuc,
      noiVaoDang: sinhvien.noiVaoDang,
      viTriCaoNhatDang: sinhvien.viTriCaoNhatDang,
    );
  }

  getDataDropdown() async {
    try {
      var response = await ApiRepository().getDataQuocGia(
          null, Globals().thongTinSinhVienModel.value?.guidDonVi);
      listQuocGia.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataTinhThanhPho(
          null, Globals().thongTinSinhVienModel.value?.guidDonVi);
      listTinhThanhPho.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataDanToc(
          null, Globals().thongTinSinhVienModel.value?.guidDonVi);
      listDanToc.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataTonGiao(
          null, Globals().thongTinSinhVienModel.value?.guidDonVi);
      listTonGiao.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataKhuVucUuTien(
          null, Globals().thongTinSinhVienModel.value?.guidDonVi);
      listKhuVucUuTien.value = response;
    } catch (e) {
      logError(e.toString());
    }

    //Get quan huyen
    try {
      String? idTinhThanhPho =
          Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenQueQuan.value = response;
      if (idTinhThanhPho ==
          Globals().thongTinSinhVienModel.value?.idNoiSinhTinhThanhPho) {
        listQuanHuyenNoiSinh.value = response;
      }
      if (idTinhThanhPho ==
          Globals()
              .thongTinSinhVienModel
              .value
              ?.idHoKhauThuongTruTinhThanhPho) {
        listQuanHuyenThuongTru.value = response;
      }
      if (idTinhThanhPho ==
          Globals().thongTinSinhVienModel.value?.idNoiOHienNayTinhThanhPho) {
        listQuanHuyenNoiOHienNay.value = response;
      }
      if (idTinhThanhPho ==
          Globals().thongTinSinhVienModel.value?.idDiaChiLienLacTinhThanhPho) {
        listQuanHuyenDiaChiLL.value = response;
      }
    } catch (e) {
      logError(e.toString());
    }

    if (Globals().thongTinSinhVienModel.value?.idNoiSinhTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho =
            Globals().thongTinSinhVienModel.value?.idNoiSinhTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenNoiSinh.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }

    if (Globals().thongTinSinhVienModel.value?.idHoKhauThuongTruTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho = Globals()
            .thongTinSinhVienModel
            .value
            ?.idHoKhauThuongTruTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenThuongTru.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }
    if (Globals().thongTinSinhVienModel.value?.idNoiOHienNayTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho =
            Globals().thongTinSinhVienModel.value?.idNoiOHienNayTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenNoiOHienNay.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }

    if (Globals().thongTinSinhVienModel.value?.idDiaChiLienLacTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho =
            Globals().thongTinSinhVienModel.value?.idDiaChiLienLacTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenDiaChiLL.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }
  }

  refreshQuanHuyenQueQuan() async {
    listQuanHuyenQueQuan.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idQueQuanTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenQueQuan.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenNoiSinh() async {
    listQuanHuyenNoiSinh.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idNoiSinhTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenNoiSinh.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenHoKhauThuongTru() async {
    listQuanHuyenThuongTru.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idHoKhauThuongTruTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenThuongTru.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenNoiOHienNay() async {
    listQuanHuyenNoiOHienNay.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idNoiOHienNayTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenNoiOHienNay.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenDiaChiLL() async {
    listQuanHuyenDiaChiLL.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idDiaChiLienLacTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenDiaChiLL.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  updatePersonInfo() async {
    //
    if (!configValueOk) {
      snackBarWarning('Không tìm thấy thông tin sinh viên');
      return;
    }
    Utils.showProgress(context);
    try {
      var response =
          await ApiRepository().updateSinhVienInfo(sinhvienEdit.value);

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
