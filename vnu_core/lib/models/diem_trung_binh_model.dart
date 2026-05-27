// To parse this JSON data, do
//
//     final diemTrungBinhModel = diemTrungBinhModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'diem_trung_binh_model.g.dart';

DiemTrungBinhModel diemTrungBinhModelFromJson(String str) =>
    DiemTrungBinhModel.fromJson(json.decode(str));

String diemTrungBinhModelToJson(DiemTrungBinhModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class DiemTrungBinhModel {
  @JsonKey(name: "diemTrungBinhHe4_HocKy")
  String? diemTrungBinhHe4HocKy;
  @JsonKey(name: "diemTrungBinhHe4_TichLuyDenHocKyHienTai")
  String? diemTrungBinhHe4TichLuyDenHocKyHienTai;
  @JsonKey(name: "diemTrungBinhHe10_HocKy")
  String? diemTrungBinhHe10HocKy;
  @JsonKey(name: "diemTrungBinhHe10_TichLuyDenHocKyHienTai")
  String? diemTrungBinhHe10TichLuyDenHocKyHienTai;
  @JsonKey(name: "tongSoTinChiTichLuy_HocKy")
  String? tongSoTinChiTichLuyHocKy;
  @JsonKey(name: "tongSoTinChiTichLuy_TichLuyDenHocKyHienTai")
  String? tongSoTinChiTichLuyTichLuyDenHocKyHienTai;
  @JsonKey(name: "tongSoTinChiTruot_HocKy")
  String? tongSoTinChiTruotHocKy;
  @JsonKey(name: "tongSoTinChiTruot_TichLuyDenHocKyHienTai")
  String? tongSoTinChiTruotTichLuyDenHocKyHienTai;

  DiemTrungBinhModel({
    this.diemTrungBinhHe4HocKy,
    this.diemTrungBinhHe4TichLuyDenHocKyHienTai,
    this.diemTrungBinhHe10HocKy,
    this.diemTrungBinhHe10TichLuyDenHocKyHienTai,
    this.tongSoTinChiTichLuyHocKy,
    this.tongSoTinChiTichLuyTichLuyDenHocKyHienTai,
    this.tongSoTinChiTruotHocKy,
    this.tongSoTinChiTruotTichLuyDenHocKyHienTai,
  });

  DiemTrungBinhModel copyWith({
    String? diemTrungBinhHe4HocKy,
    String? diemTrungBinhHe4TichLuyDenHocKyHienTai,
    String? diemTrungBinhHe10HocKy,
    String? diemTrungBinhHe10TichLuyDenHocKyHienTai,
    String? tongSoTinChiTichLuyHocKy,
    String? tongSoTinChiTichLuyTichLuyDenHocKyHienTai,
    String? tongSoTinChiTruotHocKy,
    String? tongSoTinChiTruotTichLuyDenHocKyHienTai,
  }) =>
      DiemTrungBinhModel(
        diemTrungBinhHe4HocKy:
            diemTrungBinhHe4HocKy ?? this.diemTrungBinhHe4HocKy,
        diemTrungBinhHe4TichLuyDenHocKyHienTai:
            diemTrungBinhHe4TichLuyDenHocKyHienTai ??
                this.diemTrungBinhHe4TichLuyDenHocKyHienTai,
        diemTrungBinhHe10HocKy:
            diemTrungBinhHe10HocKy ?? this.diemTrungBinhHe10HocKy,
        diemTrungBinhHe10TichLuyDenHocKyHienTai:
            diemTrungBinhHe10TichLuyDenHocKyHienTai ??
                this.diemTrungBinhHe10TichLuyDenHocKyHienTai,
        tongSoTinChiTichLuyHocKy:
            tongSoTinChiTichLuyHocKy ?? this.tongSoTinChiTichLuyHocKy,
        tongSoTinChiTichLuyTichLuyDenHocKyHienTai:
            tongSoTinChiTichLuyTichLuyDenHocKyHienTai ??
                this.tongSoTinChiTichLuyTichLuyDenHocKyHienTai,
        tongSoTinChiTruotHocKy:
            tongSoTinChiTruotHocKy ?? this.tongSoTinChiTruotHocKy,
        tongSoTinChiTruotTichLuyDenHocKyHienTai:
            tongSoTinChiTruotTichLuyDenHocKyHienTai ??
                this.tongSoTinChiTruotTichLuyDenHocKyHienTai,
      );

  factory DiemTrungBinhModel.fromJson(Map<String, dynamic> json) =>
      _$DiemTrungBinhModelFromJson(json);

  Map<String, dynamic> toJson() => _$DiemTrungBinhModelToJson(this);
}
