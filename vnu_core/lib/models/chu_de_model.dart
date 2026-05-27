// To parse this JSON data, do
//
//     final chuDeModel = chuDeModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'chu_de_model.g.dart';

ChuDeModel chuDeModelFromJson(String str) =>
    ChuDeModel.fromJson(json.decode(str));

String chuDeModelToJson(ChuDeModel data) => json.encode(data.toJson());

@JsonSerializable()
class ChuDeModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenChuDe")
  String? tenChuDe;

  ChuDeModel({
    this.guid,
    this.tenChuDe,
  });

  ChuDeModel copyWith({
    String? guid,
    String? tenChuDe,
  }) =>
      ChuDeModel(
        guid: guid ?? this.guid,
        tenChuDe: tenChuDe ?? this.tenChuDe,
      );

  factory ChuDeModel.fromJson(Map<String, dynamic> json) =>
      _$ChuDeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChuDeModelToJson(this);
}
