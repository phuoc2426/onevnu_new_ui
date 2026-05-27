// To parse this JSON data, do
//
//     final thongTinPhuHuynhModel = thongTinPhuHuynhModelFromJson(jsonString);

import 'dart:convert';

ThongTinPhuHuynhModel thongTinPhuHuynhModelFromJson(String str) =>
    ThongTinPhuHuynhModel.fromJson(json.decode(str));

String thongTinPhuHuynhModelToJson(ThongTinPhuHuynhModel data) =>
    json.encode(data.toJson());

class ThongTinPhuHuynhModel {
  ThongTinPhuHuynhModel({
    this.hoTen,
    this.namSinh,
    this.soDienThoai,
    this.ngheNghiep,
    this.noiLamViec,
  });

  String? hoTen;
  String? namSinh;
  String? soDienThoai;
  String? ngheNghiep;
  String? noiLamViec;

  factory ThongTinPhuHuynhModel.fromJson(Map<String, dynamic> json) =>
      ThongTinPhuHuynhModel(
        hoTen: json["HoTen"],
        namSinh: json["NamSinh"],
        soDienThoai: json["SoDienThoai"],
        ngheNghiep: json["NgheNghiep"],
        noiLamViec: json["NoiLamViec"],
      );

  Map<String, dynamic> toJson() => {
        "HoTen": hoTen,
        "NamSinh": namSinh,
        "SoDienThoai": soDienThoai,
        "NgheNghiep": ngheNghiep,
        "NoiLamViec": noiLamViec,
      };
}
