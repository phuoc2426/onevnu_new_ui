// To parse this JSON data, do
//
//     final diaChiThuongTruModel = diaChiThuongTruModelFromJson(jsonString);

import 'dart:convert';

ThongTinDiaChiThuongTruModel diaChiThuongTruModelFromJson(String str) =>
    ThongTinDiaChiThuongTruModel.fromJson(json.decode(str));

String diaChiThuongTruModelToJson(ThongTinDiaChiThuongTruModel data) =>
    json.encode(data.toJson());

class ThongTinDiaChiThuongTruModel {
  ThongTinDiaChiThuongTruModel({
    this.quocGia,
    this.tinhThanhPho,
    this.quanHuyen,
    this.phuongXa,
    this.diaChiChiTiet,
  });

  String? quocGia;
  String? tinhThanhPho;
  String? quanHuyen;
  String? phuongXa;
  String? diaChiChiTiet;

  factory ThongTinDiaChiThuongTruModel.fromJson(Map<String, dynamic> json) =>
      ThongTinDiaChiThuongTruModel(
        quocGia: json["QuocGia"],
        tinhThanhPho: json["TinhThanhPho"],
        quanHuyen: json["QuanHuyen"],
        phuongXa: json["PhuongXa"],
        diaChiChiTiet: json["DiaChiChiTiet"],
      );

  Map<String, dynamic> toJson() => {
        "QuocGia": quocGia,
        "TinhThanhPho": tinhThanhPho,
        "QuanHuyen": quanHuyen,
        "PhuongXa": phuongXa,
        "DiaChiChiTiet": diaChiChiTiet,
      };
}
