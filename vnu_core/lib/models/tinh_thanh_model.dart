// To parse this JSON data, do
//
//     final tinhThanhModel = tinhThanhModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'tinh_thanh_model.g.dart';

TinhThanhModel tinhThanhModelFromJson(String str) =>
    TinhThanhModel.fromJson(json.decode(str));

String tinhThanhModelToJson(TinhThanhModel data) => json.encode(data.toJson());

@JsonSerializable()
class TinhThanhModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  TinhThanhModel({
    this.id,
    this.ten,
    this.guidDonVi,
  });

  TinhThanhModel copyWith({
    String? id,
    String? ten,
    String? guidDonVi,
  }) =>
      TinhThanhModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory TinhThanhModel.fromJson(Map<String, dynamic> json) =>
      _$TinhThanhModelFromJson(json);

  Map<String, dynamic> toJson() => _$TinhThanhModelToJson(this);
}
