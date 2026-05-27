// To parse this JSON data, do
//
//     final thongNhapHocModel = thongNhapHocModelFromJson(jsonString);

import 'dart:convert';

ThongTinNhapHocModel thongNhapHocModelFromJson(String str) =>
    ThongTinNhapHocModel.fromJson(json.decode(str));

String thongNhapHocModelToJson(ThongTinNhapHocModel data) =>
    json.encode(data.toJson());

class ThongTinNhapHocModel {
  ThongTinNhapHocModel({
    this.donViDaoTao,
    this.khoa,
    this.nganh,
    this.khoaHoc,
    this.lop,
    this.namBatDau,
    this.namKetThuc,
  });

  String? donViDaoTao;
  String? khoa;
  String? nganh;
  String? khoaHoc;
  String? lop;
  String? namBatDau;
  String? namKetThuc;

  factory ThongTinNhapHocModel.fromJson(Map<String, dynamic> json) =>
      ThongTinNhapHocModel(
        donViDaoTao: json["DonViDaoTao"],
        khoa: json["Khoa"],
        nganh: json["Nganh"],
        khoaHoc: json["KhoaHoc"],
        lop: json["Lop"],
        namBatDau: json["NamBatDau"],
        namKetThuc: json["NamKetThuc"],
      );

  Map<String, dynamic> toJson() => {
        "DonViDaoTao": donViDaoTao,
        "Khoa": khoa,
        "Nganh": nganh,
        "KhoaHoc": khoaHoc,
        "Lop": lop,
        "NamBatDau": namBatDau,
        "NamKetThuc": namKetThuc,
      };
}
