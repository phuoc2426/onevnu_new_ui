// To parse this JSON data, do
//
//     final lopDaoTaoModel = lopDaoTaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'lop_dao_tao_model.g.dart';

LopDaoTaoModel lopDaoTaoModelFromJson(String str) =>
    LopDaoTaoModel.fromJson(json.decode(str));

String lopDaoTaoModelToJson(LopDaoTaoModel data) => json.encode(data.toJson());

@JsonSerializable()
class LopDaoTaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "tenVietTat")
  String? tenVietTat;
  @JsonKey(name: "kieuLopDaoTao")
  dynamic kieuLopDaoTao;
  @JsonKey(name: "idHeDaoTao")
  String? idHeDaoTao;
  @JsonKey(name: "idNganhDaoTao")
  String? idNganhDaoTao;
  @JsonKey(name: "idNienKhoaDaoTao")
  String? idNienKhoaDaoTao;
  @JsonKey(name: "idChuongTrinhDaoTao")
  String? idChuongTrinhDaoTao;
  @JsonKey(name: "idBacDaoTao")
  String? idBacDaoTao;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  LopDaoTaoModel({
    this.id,
    this.ten,
    this.tenVietTat,
    this.kieuLopDaoTao,
    this.idHeDaoTao,
    this.idNganhDaoTao,
    this.idNienKhoaDaoTao,
    this.idChuongTrinhDaoTao,
    this.idBacDaoTao,
    this.guidDonVi,
  });

  LopDaoTaoModel copyWith({
    String? id,
    String? ten,
    String? tenVietTat,
    dynamic kieuLopDaoTao,
    String? idHeDaoTao,
    String? idNganhDaoTao,
    String? idNienKhoaDaoTao,
    String? idChuongTrinhDaoTao,
    String? idBacDaoTao,
    String? guidDonVi,
  }) =>
      LopDaoTaoModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        tenVietTat: tenVietTat ?? this.tenVietTat,
        kieuLopDaoTao: kieuLopDaoTao ?? this.kieuLopDaoTao,
        idHeDaoTao: idHeDaoTao ?? this.idHeDaoTao,
        idNganhDaoTao: idNganhDaoTao ?? this.idNganhDaoTao,
        idNienKhoaDaoTao: idNienKhoaDaoTao ?? this.idNienKhoaDaoTao,
        idChuongTrinhDaoTao: idChuongTrinhDaoTao ?? this.idChuongTrinhDaoTao,
        idBacDaoTao: idBacDaoTao ?? this.idBacDaoTao,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory LopDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$LopDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$LopDaoTaoModelToJson(this);
}
