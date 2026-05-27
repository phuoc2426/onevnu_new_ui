// To parse this JSON data, do
//
//     final ntDanhSachThongBaoModel = ntDanhSachThongBaoModelFromJson(jsonString);

import 'dart:convert';

NtDanhSachThongBaoModel ntDanhSachThongBaoModelFromJson(String str) =>
    NtDanhSachThongBaoModel.fromJson(json.decode(str));

String ntDanhSachThongBaoModelToJson(NtDanhSachThongBaoModel data) =>
    json.encode(data.toJson());

class NtDanhSachThongBaoModel {
  NtDanhSachThongBaoModel({
    this.danhSachThongBao,
  });

  List<DanhSachThongBao>? danhSachThongBao;

  factory NtDanhSachThongBaoModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachThongBaoModel(
        danhSachThongBao: List<DanhSachThongBao>.from(
            (json["DanhSachThongBao"] ?? [])
                .map((x) => DanhSachThongBao.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "DanhSachThongBao":
            List<dynamic>.from((danhSachThongBao ?? []).map((x) => x.toJson())),
      };
}

class DanhSachThongBao {
  DanhSachThongBao({
    this.danhSachThongBaoId,
    this.tenNguoiDung,
    this.soDienThoai,
    this.tenDonVi,
    this.tieuDe,
    this.noiDung,
    this.trangThai,
    this.ngayGui,
    this.thoiGianGui,
    this.screenName,
  });

  int? danhSachThongBaoId;
  String? tenNguoiDung;
  String? soDienThoai;
  String? tenDonVi;
  String? tieuDe;
  dynamic noiDung;
  int? trangThai;
  String? ngayGui;
  String? thoiGianGui;
  String? screenName;

  factory DanhSachThongBao.fromJson(Map<String, dynamic> json) =>
      DanhSachThongBao(
        danhSachThongBaoId: json["ID"],
        tenNguoiDung: json["TenNguoiDung"],
        soDienThoai: json["SoDienThoai"],
        tenDonVi: json["TenDonVi"],
        tieuDe: json["TieuDe"],
        noiDung: json["NoiDung"],
        trangThai: json["TrangThai"],
        ngayGui: json["NgayGui"],
        thoiGianGui: json["ThoiGianGui"],
        screenName: json["ScreenName"],
      );

  Map<String, dynamic> toJson() => {
        "ID": danhSachThongBaoId,
        "TenNguoiDung": tenNguoiDung,
        "SoDienThoai": soDienThoai,
        "TenDonVi": tenDonVi,
        "TieuDe": tieuDe,
        "NoiDung": noiDung,
        "TrangThai": trangThai,
        "NgayGui": ngayGui,
        "ThoiGianGui": thoiGianGui,
        "ScreenName": screenName,
      };
}
