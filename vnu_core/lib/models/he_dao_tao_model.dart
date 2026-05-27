// To parse this JSON data, do
//
//     final heDaoTaoModel = heDaoTaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'he_dao_tao_model.g.dart';

HeDaoTaoModel heDaoTaoModelFromJson(String str) =>
    HeDaoTaoModel.fromJson(json.decode(str));

String heDaoTaoModelToJson(HeDaoTaoModel data) => json.encode(data.toJson());

@JsonSerializable()
class HeDaoTaoModel {
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

  HeDaoTaoModel({
    this.id,
    this.ma,
    this.ten,
    this.idBacDaoTao,
    this.guidDonVi,
  });

  HeDaoTaoModel copyWith({
    String? id,
    String? ma,
    String? ten,
    String? idBacDaoTao,
    String? guidDonVi,
  }) =>
      HeDaoTaoModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        idBacDaoTao: idBacDaoTao ?? this.idBacDaoTao,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory HeDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$HeDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$HeDaoTaoModelToJson(this);
}
