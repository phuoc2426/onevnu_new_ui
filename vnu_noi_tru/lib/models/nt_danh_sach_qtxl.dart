// To parse this JSON data, do
//
//     final ntDanhSachQtxlModel = ntDanhSachQtxlModelFromJson(jsonString);

import 'dart:convert';

NtDanhSachQtxlModel ntDanhSachQtxlModelFromJson(String str) =>
    NtDanhSachQtxlModel.fromJson(json.decode(str));

String ntDanhSachQtxlModelToJson(NtDanhSachQtxlModel data) =>
    json.encode(data.toJson());

class NtDanhSachQtxlModel {
  NtDanhSachQtxlModel({
    this.danhSachQuaTrinhXuLy,
  });

  List<DanhSachQuaTrinhXuLy>? danhSachQuaTrinhXuLy;

  factory NtDanhSachQtxlModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachQtxlModel(
        danhSachQuaTrinhXuLy: List<DanhSachQuaTrinhXuLy>.from(
            (json["DanhSachQuaTrinhXuLy"] ?? [])
                .map((x) => DanhSachQuaTrinhXuLy.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "DanhSachQuaTrinhXuLy": List<dynamic>.from(
            (danhSachQuaTrinhXuLy ?? []).map((x) => x.toJson())),
      };
}

class DanhSachQuaTrinhXuLy {
  DanhSachQuaTrinhXuLy({
    this.id,
    this.donViXuLy,
    this.nguoiXuLy,
    this.thoiGian,
    this.noiDung,
    this.trangThai,
  });

  int? id;
  String? donViXuLy;
  String? nguoiXuLy;
  String? thoiGian;
  String? noiDung;
  String? trangThai;

  factory DanhSachQuaTrinhXuLy.fromJson(Map<String, dynamic> json) =>
      DanhSachQuaTrinhXuLy(
        id: json["Id"],
        donViXuLy: json["DonViXuLy"],
        nguoiXuLy: json["NguoiXuLy"],
        thoiGian: json["ThoiGian"] == null ? null : json["ThoiGian"],
        noiDung: json["NoiDung"] == null ? null : json["NoiDung"],
        trangThai: json["TrangThai"],
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "DonViXuLy": donViXuLy,
        "NguoiXuLy": nguoiXuLy,
        "ThoiGian": thoiGian == null ? null : thoiGian,
        "NoiDung": noiDung == null ? null : noiDung,
        "TrangThai": trangThai,
      };
}
