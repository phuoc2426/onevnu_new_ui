// To parse this JSON data, do
//
//     final nganhDaoTaoModel = nganhDaoTaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'nganh_dao_tao_model.g.dart';

NganhDaoTaoModel nganhDaoTaoModelFromJson(String str) =>
    NganhDaoTaoModel.fromJson(json.decode(str));

String nganhDaoTaoModelToJson(NganhDaoTaoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class NganhDaoTaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  String? ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "idBacDaoTao")
  String? idBacDaoTao;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  NganhDaoTaoModel({
    this.id,
    this.ma,
    this.ten,
    this.idBacDaoTao,
    this.guidDonVi,
  });

  NganhDaoTaoModel copyWith({
    String? id,
    String? ma,
    String? ten,
    String? idBacDaoTao,
    String? guidDonVi,
  }) =>
      NganhDaoTaoModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        idBacDaoTao: idBacDaoTao ?? this.idBacDaoTao,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory NganhDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$NganhDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$NganhDaoTaoModelToJson(this);
}
