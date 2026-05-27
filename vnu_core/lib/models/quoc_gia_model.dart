// To parse this JSON data, do
//
//     final quocGiaModel = quocGiaModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'quoc_gia_model.g.dart';

QuocGiaModel quocGiaModelFromJson(String str) =>
    QuocGiaModel.fromJson(json.decode(str));

String quocGiaModelToJson(QuocGiaModel data) => json.encode(data.toJson());

@JsonSerializable()
class QuocGiaModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  QuocGiaModel({
    this.id,
    this.ten,
    this.guidDonVi,
  });

  QuocGiaModel copyWith({
    String? id,
    String? ten,
    String? guidDonVi,
  }) =>
      QuocGiaModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory QuocGiaModel.fromJson(Map<String, dynamic> json) =>
      _$QuocGiaModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuocGiaModelToJson(this);
}
