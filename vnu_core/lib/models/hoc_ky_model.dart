// To parse this JSON data, do
//
//     final hocKyModel = hocKyModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'hoc_ky_model.g.dart';

HocKyModel hocKyModelFromJson(String str) =>
    HocKyModel.fromJson(json.decode(str));

String hocKyModelToJson(HocKyModel data) => json.encode(data.toJson());

@JsonSerializable()
class HocKyModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "nam")
  String? nam;
  @JsonKey(name: "maHocKy")
  String? maHocKy;
  @JsonKey(name: "ngayBatDau")
  String? ngayBatDau;
  @JsonKey(name: "ngayKetThuc")
  String? ngayKetThuc;
  @JsonKey(name: "preTerm")
  String? preTerm;
  @JsonKey(name: "loaiHocKy")
  String? loaiHocKy;

  HocKyModel({
    this.id,
    this.ten,
    this.nam,
    this.maHocKy,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.preTerm,
    this.loaiHocKy,
  });

  String disPlayName() {
    return 'Kỳ $ten năm $nam';
  }

  HocKyModel copyWith({
    String? id,
    String? ten,
    String? nam,
    String? maHocKy,
    String? ngayBatDau,
    String? ngayKetThuc,
    String? preTerm,
    String? loaiHocKy,
  }) =>
      HocKyModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        nam: nam ?? this.nam,
        maHocKy: maHocKy ?? this.maHocKy,
        ngayBatDau: ngayBatDau ?? this.ngayBatDau,
        ngayKetThuc: ngayKetThuc ?? this.ngayKetThuc,
        preTerm: preTerm ?? this.preTerm,
        loaiHocKy: loaiHocKy ?? this.loaiHocKy,
      );

  factory HocKyModel.fromJson(Map<String, dynamic> json) =>
      _$HocKyModelFromJson(json);

  Map<String, dynamic> toJson() => _$HocKyModelToJson(this);
}
