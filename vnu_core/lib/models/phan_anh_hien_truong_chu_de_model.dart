// To parse this JSON data, do
//
//     final phanAnhHienTruongChuDeModel = phanAnhHienTruongChuDeModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'phan_anh_hien_truong_chu_de_model.g.dart';

PhanAnhHienTruongChuDeModel phanAnhHienTruongChuDeModelFromJson(String str) =>
    PhanAnhHienTruongChuDeModel.fromJson(json.decode(str));

String phanAnhHienTruongChuDeModelToJson(PhanAnhHienTruongChuDeModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class PhanAnhHienTruongChuDeModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenChuDe")
  String? tenChuDe;

  PhanAnhHienTruongChuDeModel({
    this.guid,
    this.tenChuDe,
  });

  PhanAnhHienTruongChuDeModel copyWith({
    String? guid,
    String? tenChuDe,
  }) =>
      PhanAnhHienTruongChuDeModel(
        guid: guid ?? this.guid,
        tenChuDe: tenChuDe ?? this.tenChuDe,
      );

  factory PhanAnhHienTruongChuDeModel.fromJson(Map<String, dynamic> json) =>
      _$PhanAnhHienTruongChuDeModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhanAnhHienTruongChuDeModelToJson(this);
}
