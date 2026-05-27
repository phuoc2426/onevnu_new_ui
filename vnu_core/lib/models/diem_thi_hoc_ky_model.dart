// To parse this JSON data, do
//
//     final diemThiHocKyModel = diemThiHocKyModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'diem_thi_hoc_ky_model.g.dart';

DiemThiHocKyModel diemThiHocKyModelFromJson(String str) =>
    DiemThiHocKyModel.fromJson(json.decode(str));

String diemThiHocKyModelToJson(DiemThiHocKyModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class DiemThiHocKyModel {
  @JsonKey(name: "idHocPhan")
  String? idHocPhan;
  @JsonKey(name: "tenHocPhan")
  String? tenHocPhan;
  @JsonKey(name: "maHocPhan")
  String? maHocPhan;
  @JsonKey(name: "soTinChi")
  String? soTinChi;
  @JsonKey(name: "diemHe10")
  String? diemHe10;
  @JsonKey(name: "diemHeChu")
  String? diemHeChu;
  @JsonKey(name: "diemHe4")
  String? diemHe4;
  @JsonKey(name: "ketQua")
  String? ketQua;
  @JsonKey(name: "idHocKy")
  String? idHocKy;

  DiemThiHocKyModel({
    this.idHocPhan,
    this.tenHocPhan,
    this.maHocPhan,
    this.soTinChi,
    this.diemHe10,
    this.diemHeChu,
    this.diemHe4,
    this.ketQua,
    this.idHocKy,
  });

  DiemThiHocKyModel copyWith({
    String? idHocPhan,
    String? tenHocPhan,
    String? maHocPhan,
    String? soTinChi,
    String? diemHe10,
    String? diemHeChu,
    String? diemHe4,
    String? ketQua,
    String? idHocKy,
  }) =>
      DiemThiHocKyModel(
        idHocPhan: idHocPhan ?? this.idHocPhan,
        tenHocPhan: tenHocPhan ?? this.tenHocPhan,
        maHocPhan: maHocPhan ?? this.maHocPhan,
        soTinChi: soTinChi ?? this.soTinChi,
        diemHe10: diemHe10 ?? this.diemHe10,
        diemHeChu: diemHeChu ?? this.diemHeChu,
        diemHe4: diemHe4 ?? this.diemHe4,
        ketQua: ketQua ?? this.ketQua,
        idHocKy: idHocKy ?? this.idHocKy,
      );

  factory DiemThiHocKyModel.fromJson(Map<String, dynamic> json) =>
      _$DiemThiHocKyModelFromJson(json);

  Map<String, dynamic> toJson() => _$DiemThiHocKyModelToJson(this);
}
