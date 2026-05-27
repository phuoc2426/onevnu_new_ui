// To parse this JSON data, do
//
//     final doiTuongUuTienModel = doiTuongUuTienModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'doi_tuong_uu_tien_model.g.dart';

DoiTuongUuTienModel doiTuongUuTienModelFromJson(String str) =>
    DoiTuongUuTienModel.fromJson(json.decode(str));

String doiTuongUuTienModelToJson(DoiTuongUuTienModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class DoiTuongUuTienModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  String? ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  DoiTuongUuTienModel({
    this.id,
    this.ma,
    this.ten,
    this.guidDonVi,
  });

  DoiTuongUuTienModel copyWith({
    String? id,
    String? ma,
    String? ten,
    String? guidDonVi,
  }) =>
      DoiTuongUuTienModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory DoiTuongUuTienModel.fromJson(Map<String, dynamic> json) =>
      _$DoiTuongUuTienModelFromJson(json);

  Map<String, dynamic> toJson() => _$DoiTuongUuTienModelToJson(this);
}
