// To parse this JSON data, do
//
//     final thongTinLienHeModel = thongTinLienHeModelFromJson(jsonString);

import 'dart:convert';

ThongTinLienHeModel thongTinLienHeModelFromJson(String str) =>
    ThongTinLienHeModel.fromJson(json.decode(str));

String thongTinLienHeModelToJson(ThongTinLienHeModel data) =>
    json.encode(data.toJson());

class ThongTinLienHeModel {
  ThongTinLienHeModel({
    this.email,
    this.soDienThoai,
    this.diaChiLienHe,
  });

  String? email;
  String? soDienThoai;
  String? diaChiLienHe;

  factory ThongTinLienHeModel.fromJson(Map<String, dynamic> json) =>
      ThongTinLienHeModel(
        email: json["Email"],
        soDienThoai: json["SoDienThoai"],
        diaChiLienHe: json["DiaChiLienHe"],
      );

  Map<String, dynamic> toJson() => {
        "Email": email,
        "SoDienThoai": soDienThoai,
        "DiaChiLienHe": diaChiLienHe,
      };
}
