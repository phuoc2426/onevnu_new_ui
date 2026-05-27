// To parse this JSON data, do
//
//     final nguonTuyenSinhModel = nguonTuyenSinhModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'nguon_tuyen_sinh_model.g.dart';

NguonTuyenSinhModel nguonTuyenSinhModelFromJson(String str) =>
    NguonTuyenSinhModel.fromJson(json.decode(str));

String nguonTuyenSinhModelToJson(NguonTuyenSinhModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class NguonTuyenSinhModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  dynamic ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  NguonTuyenSinhModel({
    this.id,
    this.ma,
    this.ten,
    this.guidDonVi,
  });

  NguonTuyenSinhModel copyWith({
    String? id,
    dynamic ma,
    String? ten,
    String? guidDonVi,
  }) =>
      NguonTuyenSinhModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory NguonTuyenSinhModel.fromJson(Map<String, dynamic> json) =>
      _$NguonTuyenSinhModelFromJson(json);

  Map<String, dynamic> toJson() => _$NguonTuyenSinhModelToJson(this);
}
