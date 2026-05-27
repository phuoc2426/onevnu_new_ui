// To parse this JSON data, do
//
//     final bacDaoTaoModel = bacDaoTaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'bac_dao_tao_model.g.dart';

BacDaoTaoModel bacDaoTaoModelFromJson(String str) =>
    BacDaoTaoModel.fromJson(json.decode(str));

String bacDaoTaoModelToJson(BacDaoTaoModel data) => json.encode(data.toJson());

@JsonSerializable()
class BacDaoTaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  String? ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  BacDaoTaoModel({
    this.id,
    this.ma,
    this.ten,
    this.guidDonVi,
  });

  BacDaoTaoModel copyWith({
    String? id,
    String? ma,
    String? ten,
    String? guidDonVi,
  }) =>
      BacDaoTaoModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory BacDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$BacDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$BacDaoTaoModelToJson(this);
}
