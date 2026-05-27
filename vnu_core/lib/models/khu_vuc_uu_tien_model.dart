// To parse this JSON data, do
//
//     final khuVucUuTienModel = khuVucUuTienModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'khu_vuc_uu_tien_model.g.dart';

KhuVucUuTienModel khuVucUuTienModelFromJson(String str) =>
    KhuVucUuTienModel.fromJson(json.decode(str));

String khuVucUuTienModelToJson(KhuVucUuTienModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class KhuVucUuTienModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  dynamic ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  KhuVucUuTienModel({
    this.id,
    this.ma,
    this.ten,
    this.guidDonVi,
  });

  KhuVucUuTienModel copyWith({
    String? id,
    dynamic ma,
    String? ten,
    String? guidDonVi,
  }) =>
      KhuVucUuTienModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory KhuVucUuTienModel.fromJson(Map<String, dynamic> json) =>
      _$KhuVucUuTienModelFromJson(json);

  Map<String, dynamic> toJson() => _$KhuVucUuTienModelToJson(this);
}
