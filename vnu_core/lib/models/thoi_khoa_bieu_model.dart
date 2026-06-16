// To parse this JSON data, do
//
//     final thoiKhoaBieuModel = thoiKhoaBieuModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'thoi_khoa_bieu_model.g.dart';

ThoiKhoaBieuModel thoiKhoaBieuModelFromJson(String str) =>
    ThoiKhoaBieuModel.fromJson(json.decode(str));

String thoiKhoaBieuModelToJson(ThoiKhoaBieuModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class ThoiKhoaBieuModel {
  @JsonKey(name: "tenHocPhan")
  String? tenHocPhan;
  @JsonKey(name: "soTinChi")
  String? soTinChi;
  @JsonKey(name: "maHocPhan")
  String? maHocPhan;
  @JsonKey(name: "nhom")
  String? nhom;
  @JsonKey(name: "tietBatDau")
  String? tietBatDau;
  @JsonKey(name: "tietKetThuc")
  String? tietKetThuc;
  @JsonKey(name: "ngayBatDau")
  String? ngayBatDau;
  @JsonKey(name: "ngayKetThuc")
  String? ngayKetThuc;
  @JsonKey(name: "ngayTrongTuan")
  String? ngayTrongTuan;
  @JsonKey(name: "diaChi")
  String? diaChi;
  @JsonKey(name: "tenPhong")
  String? tenPhong;
  @JsonKey(name: "giangVien1")
  String? giangVien1;
  @JsonKey(name: "giangVien2")
  String? giangVien2;
  @JsonKey(name: "giangVien3")
  String? giangVien3;
  @JsonKey(name: "giangVien4")
  String? giangVien4;

  ThoiKhoaBieuModel({
    this.tenHocPhan,
    this.soTinChi,
    this.maHocPhan,
    this.nhom,
    this.tietBatDau,
    this.tietKetThuc,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.ngayTrongTuan,
    this.diaChi,
    this.tenPhong,
    this.giangVien1,
    this.giangVien2,
    this.giangVien3,
    this.giangVien4,
  });

  ThoiKhoaBieuModel copyWith({
    String? tenHocPhan,
    String? soTinChi,
    String? maHocPhan,
    String? nhom,
    String? tietBatDau,
    String? tietKetThuc,
    String? ngayBatDau,
    String? ngayKetThuc,
    String? ngayTrongTuan,
    String? diaChi,
    String? tenPhong,
    String? giangVien1,
    String? giangVien2,
    String? giangVien3,
    String? giangVien4,
  }) =>
      ThoiKhoaBieuModel(
        tenHocPhan: tenHocPhan ?? this.tenHocPhan,
        soTinChi: soTinChi ?? this.soTinChi,
        maHocPhan: maHocPhan ?? this.maHocPhan,
        nhom: nhom ?? this.nhom,
        tietBatDau: tietBatDau ?? this.tietBatDau,
        tietKetThuc: tietKetThuc ?? this.tietKetThuc,
        ngayBatDau: ngayBatDau ?? this.ngayBatDau,
        ngayKetThuc: ngayKetThuc ?? this.ngayKetThuc,
        ngayTrongTuan: ngayTrongTuan ?? this.ngayTrongTuan,
        diaChi: diaChi ?? this.diaChi,
        tenPhong: tenPhong ?? this.tenPhong,
        giangVien1: giangVien1 ?? this.giangVien1,
        giangVien2: giangVien2 ?? this.giangVien2,
        giangVien3: giangVien3 ?? this.giangVien3,
        giangVien4: giangVien4 ?? this.giangVien4,
      );

  factory ThoiKhoaBieuModel.fromJson(Map<String, dynamic> json) =>
      _$ThoiKhoaBieuModelFromJson(json);

  Map<String, dynamic> toJson() => _$ThoiKhoaBieuModelToJson(this);

  String getNgayTrongTuan() {
    switch (ngayTrongTuan) {
      case '1':
        return 'Thứ 2';
      case '2':
        return 'Thứ 3';
      case '3':
        return 'Thứ 4';
      case '4':
        return 'Thứ 5';
      case '5':
        return 'Thứ 6';
      case '6':
        return 'Thứ 7';
      case '7':
        return 'Chủ nhật';
      default:
        return '';
    }
  }
}
