// To parse this JSON data, do
//
//     final donViModel = donViModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'don_vi_model.g.dart';

DonViModel donViModelFromJson(String str) =>
    DonViModel.fromJson(json.decode(str));

String donViModelToJson(DonViModel data) => json.encode(data.toJson());

@JsonSerializable()
class DonViModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenDonVi")
  String? tenDonVi;
  @JsonKey(name: "guidDonViCha")
  String? guidDonViCha;
  @JsonKey(name: "capDonVi")
  int? capDonVi;
  @JsonKey(name: "thuTu")
  int? thuTu;
  @JsonKey(name: "idHeThongDaoTao")
  int? idHeThongDaoTao;

  DonViModel({
    this.guid,
    this.tenDonVi,
    this.guidDonViCha,
    this.capDonVi,
    this.thuTu,
    this.idHeThongDaoTao,
  });

  DonViModel copyWith({
    String? guid,
    String? tenDonVi,
    String? guidDonViCha,
    int? capDonVi,
    int? thuTu,
    int? idHeThongDaoTao,
  }) =>
      DonViModel(
        guid: guid ?? this.guid,
        tenDonVi: tenDonVi ?? this.tenDonVi,
        guidDonViCha: guidDonViCha ?? this.guidDonViCha,
        capDonVi: capDonVi ?? this.capDonVi,
        thuTu: thuTu ?? this.thuTu,
        idHeThongDaoTao: idHeThongDaoTao ?? this.idHeThongDaoTao,
      );

  factory DonViModel.fromJson(Map<String, dynamic> json) =>
      _$DonViModelFromJson(json);

  Map<String, dynamic> toJson() => _$DonViModelToJson(this);
}
