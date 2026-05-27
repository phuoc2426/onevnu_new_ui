// To parse this JSON data, do
//
//     final ntDanhSachDoiTuongUuTienModel = ntDanhSachDoiTuongUuTienModelFromJson(jsonString);

import 'dart:convert';

NtDanhSachDoiTuongUuTienModel ntDanhSachDoiTuongUuTienModelFromJson(
        String str) =>
    NtDanhSachDoiTuongUuTienModel.fromJson(json.decode(str));

String ntDanhSachDoiTuongUuTienModelToJson(
        NtDanhSachDoiTuongUuTienModel data) =>
    json.encode(data.toJson());

class NtDanhSachDoiTuongUuTienModel {
  NtDanhSachDoiTuongUuTienModel({
    this.danhSachDoiTuongUuTien,
  });

  List<DanhSachDoiTuongUuTien>? danhSachDoiTuongUuTien;

  factory NtDanhSachDoiTuongUuTienModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachDoiTuongUuTienModel(
        danhSachDoiTuongUuTien: List<DanhSachDoiTuongUuTien>.from(
            (json["DanhSachDoiTuongUuTien"] ?? [])
                .map((x) => DanhSachDoiTuongUuTien.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "DanhSachDoiTuongUuTien": List<dynamic>.from(
            (danhSachDoiTuongUuTien ?? []).map((x) => x.toJson())),
      };
}

class DanhSachDoiTuongUuTien {
  DanhSachDoiTuongUuTien({
    this.id,
    this.ID_DotDangKy,
    this.tenDoiTuongUuTien,
    this.prefix,
  });

  int? id;
  int? ID_DotDangKy;
  String? tenDoiTuongUuTien;
  String? prefix;

  //local
  bool iselected = false;

  factory DanhSachDoiTuongUuTien.fromJson(Map<String, dynamic> json) =>
      DanhSachDoiTuongUuTien(
        id: json["Id"],
        tenDoiTuongUuTien: json["TenDoiTuongUuTien"],
        prefix: json["Prefix"],
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "TenDoiTuongUuTien": tenDoiTuongUuTien,
        "Prefix": prefix,
      };
}
