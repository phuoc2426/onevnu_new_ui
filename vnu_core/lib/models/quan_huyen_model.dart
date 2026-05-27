// To parse this JSON data, do
//
//     final quanHuyenModel = quanHuyenModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'quan_huyen_model.g.dart';

QuanHuyenModel quanHuyenModelFromJson(String str) =>
    QuanHuyenModel.fromJson(json.decode(str));

String quanHuyenModelToJson(QuanHuyenModel data) => json.encode(data.toJson());

@JsonSerializable()
class QuanHuyenModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "idTinhThanhPho")
  String? idTinhThanhPho;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  QuanHuyenModel({
    this.id,
    this.ten,
    this.idTinhThanhPho,
    this.guidDonVi,
  });

  QuanHuyenModel copyWith({
    String? id,
    String? ten,
    String? idTinhThanhPho,
    String? guidDonVi,
  }) =>
      QuanHuyenModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        idTinhThanhPho: idTinhThanhPho ?? this.idTinhThanhPho,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory QuanHuyenModel.fromJson(Map<String, dynamic> json) =>
      _$QuanHuyenModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuanHuyenModelToJson(this);
}
