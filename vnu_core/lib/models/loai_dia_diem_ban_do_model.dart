// To parse this JSON data, do
//
//     final loaiDiaDiemBanDoModel = loaiDiaDiemBanDoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'loai_dia_diem_ban_do_model.g.dart';

LoaiDiaDiemBanDoModel loaiDiaDiemBanDoModelFromJson(String str) =>
    LoaiDiaDiemBanDoModel.fromJson(json.decode(str));

String loaiDiaDiemBanDoModelToJson(LoaiDiaDiemBanDoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class LoaiDiaDiemBanDoModel {
  @JsonKey(name: "icon")
  String? icon;
  @JsonKey(name: "tenLoaiDiaDiemBanDo")
  String? tenLoaiDiaDiemBanDo;
  @JsonKey(name: "thuTu")
  int? thuTu;
  @JsonKey(name: "guid")
  String? guid;

  LoaiDiaDiemBanDoModel({
    this.icon,
    this.tenLoaiDiaDiemBanDo,
    this.thuTu,
    this.guid,
  });

  LoaiDiaDiemBanDoModel copyWith({
    String? icon,
    String? tenLoaiDiaDiemBanDo,
    int? thuTu,
    String? guid,
  }) =>
      LoaiDiaDiemBanDoModel(
        icon: icon ?? this.icon,
        tenLoaiDiaDiemBanDo: tenLoaiDiaDiemBanDo ?? this.tenLoaiDiaDiemBanDo,
        thuTu: thuTu ?? this.thuTu,
        guid: guid ?? this.guid,
      );

  factory LoaiDiaDiemBanDoModel.fromJson(Map<String, dynamic> json) =>
      _$LoaiDiaDiemBanDoModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoaiDiaDiemBanDoModelToJson(this);
}
