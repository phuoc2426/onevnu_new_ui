// To parse this JSON data, do
//
//     final ntDanhSachDotDangKyLuuTruModel = ntDanhSachDotDangKyLuuTruModelFromJson(jsonString);

import 'dart:convert';

NtDanhSachDotDangKyLuuTruModel ntDanhSachDotDangKyLuuTruModelFromJson(
        String str) =>
    NtDanhSachDotDangKyLuuTruModel.fromJson(json.decode(str));

String ntDanhSachDotDangKyLuuTruModelToJson(
        NtDanhSachDotDangKyLuuTruModel data) =>
    json.encode(data.toJson());

class NtDanhSachDotDangKyLuuTruModel {
  NtDanhSachDotDangKyLuuTruModel({
    this.danhSachDotDangKyLuuTru,
  });

  List<DanhSachDotDangKyLuuTru>? danhSachDotDangKyLuuTru;

  factory NtDanhSachDotDangKyLuuTruModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachDotDangKyLuuTruModel(
        danhSachDotDangKyLuuTru: List<DanhSachDotDangKyLuuTru>.from(
            (json["DanhSachDotDangKyLuuTru"] ?? [])
                .map((x) => DanhSachDotDangKyLuuTru.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "DanhSachDotDangKyLuuTru": List<DanhSachDotDangKyLuuTru>.from(
            (danhSachDotDangKyLuuTru ?? []).map((x) => x.toJson())),
      };
}

class DanhSachDotDangKyLuuTru {
  DanhSachDotDangKyLuuTru({
    this.id,
    this.ID_DotDangKy,
    this.tenDotDangKy,
  });

  int? id;
  int? ID_DotDangKy;
  String? tenDotDangKy;

  factory DanhSachDotDangKyLuuTru.fromJson(Map<String, dynamic> json) =>
      DanhSachDotDangKyLuuTru(
        id: json["Id"],
        ID_DotDangKy: json['ID_DotDangKy'],
        tenDotDangKy: json["TenDotDangKy"],
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        'ID_DotDangKy': ID_DotDangKy,
        "TenDotDangKy": tenDotDangKy,
      };
}
