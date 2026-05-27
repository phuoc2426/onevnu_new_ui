// To parse this JSON data, do
//
//     final diaDiemBanDoModel = diaDiemBanDoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'dia_diem_ban_do_model.g.dart';

DiaDiemBanDoModel diaDiemBanDoModelFromJson(String str) =>
    DiaDiemBanDoModel.fromJson(json.decode(str));

String diaDiemBanDoModelToJson(DiaDiemBanDoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class DiaDiemBanDoModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenKhuVucBanDo")
  String? tenKhuVucBanDo;
  @JsonKey(name: "tenLoaiDiaDiemBanDo")
  String? tenLoaiDiaDiemBanDo;
  @JsonKey(name: "tenDiaDiem")
  String? tenDiaDiem;
  @JsonKey(name: "kinhDoViDo")
  String? kinhDoViDo;
  @JsonKey(name: "guidKhuVucBanDo")
  String? guidKhuVucBanDo;
  @JsonKey(name: "guidLoaiDiaDiemBanDo")
  String? guidLoaiDiaDiemBanDo;

  DiaDiemBanDoModel({
    this.guid,
    this.tenKhuVucBanDo,
    this.tenLoaiDiaDiemBanDo,
    this.tenDiaDiem,
    this.kinhDoViDo,
    this.guidKhuVucBanDo,
    this.guidLoaiDiaDiemBanDo,
  });

  DiaDiemBanDoModel copyWith({
    String? guid,
    String? tenKhuVucBanDo,
    String? tenLoaiDiaDiemBanDo,
    String? tenDiaDiem,
    String? kinhDoViDo,
    String? guidKhuVucBanDo,
    String? guidLoaiDiaDiemBanDo,
  }) =>
      DiaDiemBanDoModel(
        guid: guid ?? this.guid,
        tenKhuVucBanDo: tenKhuVucBanDo ?? this.tenKhuVucBanDo,
        tenLoaiDiaDiemBanDo: tenLoaiDiaDiemBanDo ?? this.tenLoaiDiaDiemBanDo,
        tenDiaDiem: tenDiaDiem ?? this.tenDiaDiem,
        kinhDoViDo: kinhDoViDo ?? this.kinhDoViDo,
        guidKhuVucBanDo: guidKhuVucBanDo ?? this.guidKhuVucBanDo,
        guidLoaiDiaDiemBanDo: guidLoaiDiaDiemBanDo ?? this.guidLoaiDiaDiemBanDo,
      );

  factory DiaDiemBanDoModel.fromJson(Map<String, dynamic> json) =>
      _$DiaDiemBanDoModelFromJson(json);

  Map<String, dynamic> toJson() => _$DiaDiemBanDoModelToJson(this);
}
