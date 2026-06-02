import 'package:vnu_core/constants/enum.dart';

class BoxServiceModel {
  String? guid;
  String? tenBoxDichVu;
  String? icon;
  String? loaiBoxDichVuEnum;
  int thuTu;

  BoxServiceModel({
    this.guid,
    this.tenBoxDichVu,
    this.icon,
    this.loaiBoxDichVuEnum,
    this.thuTu = 0,
  });

  BoxServiceModel copyWith({
    String? guid,
    String? tenBoxDichVu,
    String? icon,
    int? thuTu,
    String? loaiBoxDichVuEnum,
  }) => BoxServiceModel(
    guid: guid ?? this.guid,
    tenBoxDichVu: tenBoxDichVu ?? this.tenBoxDichVu,
    icon: icon ?? this.icon,
    loaiBoxDichVuEnum: loaiBoxDichVuEnum ?? this.loaiBoxDichVuEnum,
    thuTu: thuTu ?? this.thuTu,
  );

  factory BoxServiceModel.fromJson(Map<String, dynamic> json) =>
      BoxServiceModel(
        guid: json["guid"],
        tenBoxDichVu: json["tenBoxDichVu"],
        icon: json["icon"],
        loaiBoxDichVuEnum: json["loaiBoxDichVuEnum"],
        thuTu: json["thuTu"],
      );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'guid': guid,
      'tenBoxDichVu': tenBoxDichVu,
      'icon': icon,
      'loaiBoxDichVuEnum': loaiBoxDichVuEnum,
      'thuTu': thuTu,
    };
  }
}

extension BoxService on String {
  HomeService? mapTypeBoxService() {
    switch (this) {
      case "DangKyKiTucXa":
        return HomeService.DangKyNoiTru;
      case "XemThoiKhoaBieu":
        return HomeService.XemThoiKhoaBieu;
      case "DiemMonHoc":
        return HomeService.DiemMonHoc;
      case "CamNang":
        return HomeService.CamNang;
      case "BanDoSo":
        return HomeService.BanDoSo;
      case "TimPhongTro":
        return HomeService.TimPhongTro;
      case "HuongDanSuDung":
        return HomeService.HuongDanSuDung;
      case "MucHoiDap":
        return HomeService.MucHoiDap;
      case "ThuTucMotCua":
        return HomeService.ThuTucMotCua;
      case "XemLichThi":
        return HomeService.XemLichThi;
      case "PhanAnhHienTruong":
        return HomeService.PhanAnhHienTruong;
      case "TheSinhVien":
        return HomeService.TheSinhVien;
      case "DongBo":
      case "DongBoKtx":
      case "DongBoNoiTru":
      case "KtxSync":
      case "SyncKtx":
        return HomeService.DongBo;
    }

    return null;
  }
}
