// To parse this JSON data, do
//
//     final lienKetDanhDauModel = lienKetDanhDauModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'lien_ket_danh_dau_model.g.dart';

LienKetDanhDauModel lienKetDanhDauModelFromJson(String str) =>
    LienKetDanhDauModel.fromJson(json.decode(str));

String lienKetDanhDauModelToJson(LienKetDanhDauModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class LienKetDanhDauModel {
  @JsonKey(name: "lienKet")
  String? lienKet;
  @JsonKey(name: "tenLienKet")
  String? tenLienKet;
  @JsonKey(name: "guid")
  String? guid;

  LienKetDanhDauModel({
    this.lienKet,
    this.tenLienKet,
    this.guid,
  });

  LienKetDanhDauModel copyWith({
    String? lienKet,
    String? tenLienKet,
    String? guid,
  }) =>
      LienKetDanhDauModel(
        lienKet: lienKet ?? this.lienKet,
        tenLienKet: tenLienKet ?? this.tenLienKet,
        guid: guid ?? this.guid,
      );

  factory LienKetDanhDauModel.fromJson(Map<String, dynamic> json) =>
      _$LienKetDanhDauModelFromJson(json);

  Map<String, dynamic> toJson() => _$LienKetDanhDauModelToJson(this);
}
