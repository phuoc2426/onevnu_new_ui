// To parse this JSON data, do
//
//     final danTocModel = danTocModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'dan_toc_model.g.dart';

DanTocModel danTocModelFromJson(String str) =>
    DanTocModel.fromJson(json.decode(str));

String danTocModelToJson(DanTocModel data) => json.encode(data.toJson());

@JsonSerializable()
class DanTocModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  DanTocModel({
    this.id,
    this.ten,
    this.guidDonVi,
  });

  DanTocModel copyWith({
    String? id,
    String? ten,
    String? guidDonVi,
  }) =>
      DanTocModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory DanTocModel.fromJson(Map<String, dynamic> json) =>
      _$DanTocModelFromJson(json);

  Map<String, dynamic> toJson() => _$DanTocModelToJson(this);
}
