// To parse this JSON data, do
//
//     final lichThiHocKyModel = lichThiHocKyModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'lich_thi_hoc_ky_model.g.dart';

LichThiHocKyModel lichThiHocKyModelFromJson(String str) =>
    LichThiHocKyModel.fromJson(json.decode(str));

String lichThiHocKyModelToJson(LichThiHocKyModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class LichThiHocKyModel {
  @JsonKey(name: "idLichThi")
  String? idLichThi;
  @JsonKey(name: "tenHocPhan")
  String? tenHocPhan;
  @JsonKey(name: "maHocPhan")
  String? maHocPhan;
  @JsonKey(name: "soTinChi")
  String? soTinChi;
  @JsonKey(name: "maLichThi")
  String? maLichThi;
  @JsonKey(name: "phongThi")
  String? phongThi;
  @JsonKey(name: "diaChi")
  String? diaChi;
  @JsonKey(name: "hinhThucThi")
  String? hinhThucThi;
  @JsonKey(name: "ngayThi")
  String? ngayThi;
  @JsonKey(name: "gioBatDauThi")
  String? gioBatDauThi;
  @JsonKey(name: "caThi")
  String? caThi;
  @JsonKey(name: "thoiLuong")
  String? thoiLuong;
  @JsonKey(name: "sobaodanh")
  String? sobaodanh;

  LichThiHocKyModel({
    this.idLichThi,
    this.tenHocPhan,
    this.maHocPhan,
    this.soTinChi,
    this.maLichThi,
    this.phongThi,
    this.diaChi,
    this.hinhThucThi,
    this.ngayThi,
    this.gioBatDauThi,
    this.caThi,
    this.thoiLuong,
  });

  LichThiHocKyModel copyWith({
    String? idLichThi,
    String? tenHocPhan,
    String? maHocPhan,
    String? soTinChi,
    String? maLichThi,
    String? phongThi,
    String? diaChi,
    String? hinhThucThi,
    String? ngayThi,
    String? gioBatDauThi,
    String? caThi,
    String? thoiLuong,
  }) =>
      LichThiHocKyModel(
        idLichThi: idLichThi ?? this.idLichThi,
        tenHocPhan: tenHocPhan ?? this.tenHocPhan,
        maHocPhan: maHocPhan ?? this.maHocPhan,
        soTinChi: soTinChi ?? this.soTinChi,
        maLichThi: maLichThi ?? this.maLichThi,
        phongThi: phongThi ?? this.phongThi,
        diaChi: diaChi ?? this.diaChi,
        hinhThucThi: hinhThucThi ?? this.hinhThucThi,
        ngayThi: ngayThi ?? this.ngayThi,
        gioBatDauThi: gioBatDauThi ?? this.gioBatDauThi,
        caThi: caThi ?? this.caThi,
        thoiLuong: thoiLuong ?? this.thoiLuong,
      );

  factory LichThiHocKyModel.fromJson(Map<String, dynamic> json) =>
      _$LichThiHocKyModelFromJson(json);

  Map<String, dynamic> toJson() => _$LichThiHocKyModelToJson(this);
}
