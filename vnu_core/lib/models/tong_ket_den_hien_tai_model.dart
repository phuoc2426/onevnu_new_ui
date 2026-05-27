// To parse this JSON data, do
//
//     final tongKetDenHienTaiModel = tongKetDenHienTaiModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'tong_ket_den_hien_tai_model.g.dart';

TongKetDenHienTaiModel tongKetDenHienTaiModelFromJson(String str) =>
    TongKetDenHienTaiModel.fromJson(json.decode(str));

String tongKetDenHienTaiModelToJson(TongKetDenHienTaiModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class TongKetDenHienTaiModel {
  @JsonKey(name: "soKyDaHoc")
  int? soKyDaHoc;
  @JsonKey(name: "diemTrungBinhHe4TichLuy")
  String? diemTrungBinhHe4TichLuy;
  @JsonKey(name: "tongSoTinChiTichLuy")
  String? tongSoTinChiTichLuy;

  TongKetDenHienTaiModel({
    this.soKyDaHoc,
    this.diemTrungBinhHe4TichLuy,
    this.tongSoTinChiTichLuy,
  });

  TongKetDenHienTaiModel copyWith({
    int? soKyDaHoc,
    String? diemTrungBinhHe4TichLuy,
    String? tongSoTinChiTichLuy,
  }) =>
      TongKetDenHienTaiModel(
        soKyDaHoc: soKyDaHoc ?? this.soKyDaHoc,
        diemTrungBinhHe4TichLuy:
            diemTrungBinhHe4TichLuy ?? this.diemTrungBinhHe4TichLuy,
        tongSoTinChiTichLuy: tongSoTinChiTichLuy ?? this.tongSoTinChiTichLuy,
      );

  factory TongKetDenHienTaiModel.fromJson(Map<String, dynamic> json) =>
      _$TongKetDenHienTaiModelFromJson(json);

  Map<String, dynamic> toJson() => _$TongKetDenHienTaiModelToJson(this);
}
