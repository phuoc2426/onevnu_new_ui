// To parse this JSON data, do
//
//     final tonGiaoModel = tonGiaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'ton_giao_model.g.dart';

TonGiaoModel tonGiaoModelFromJson(String str) =>
    TonGiaoModel.fromJson(json.decode(str));

String tonGiaoModelToJson(TonGiaoModel data) => json.encode(data.toJson());

@JsonSerializable()
class TonGiaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  TonGiaoModel({
    this.id,
    this.ten,
    this.guidDonVi,
  });

  TonGiaoModel copyWith({
    String? id,
    String? ten,
    String? guidDonVi,
  }) =>
      TonGiaoModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory TonGiaoModel.fromJson(Map<String, dynamic> json) =>
      _$TonGiaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TonGiaoModelToJson(this);
}
