// To parse this JSON data, do
//
//     final nienKhoaDaoTaoModel = nienKhoaDaoTaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'nien_khoa_dao_tao_model.g.dart';

NienKhoaDaoTaoModel nienKhoaDaoTaoModelFromJson(String str) =>
    NienKhoaDaoTaoModel.fromJson(json.decode(str));

String nienKhoaDaoTaoModelToJson(NienKhoaDaoTaoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class NienKhoaDaoTaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  String? ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "idBacDaoTao")
  String? idBacDaoTao;
  @JsonKey(name: "namBatDau")
  String? namBatDau;
  @JsonKey(name: "namKetThuc")
  String? namKetThuc;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  NienKhoaDaoTaoModel({
    this.id,
    this.ma,
    this.ten,
    this.idBacDaoTao,
    this.namBatDau,
    this.namKetThuc,
    this.guidDonVi,
  });

  NienKhoaDaoTaoModel copyWith({
    String? id,
    String? ma,
    String? ten,
    String? idBacDaoTao,
    String? namBatDau,
    String? namKetThuc,
    String? guidDonVi,
  }) =>
      NienKhoaDaoTaoModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        idBacDaoTao: idBacDaoTao ?? this.idBacDaoTao,
        namBatDau: namBatDau ?? this.namBatDau,
        namKetThuc: namKetThuc ?? this.namKetThuc,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory NienKhoaDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$NienKhoaDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$NienKhoaDaoTaoModelToJson(this);
}
