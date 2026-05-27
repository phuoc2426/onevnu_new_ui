// To parse this JSON data, do
//
//     final linhVucModel = linhVucModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'linh_vuc_model.g.dart';

LinhVucModel linhVucModelFromJson(String str) =>
    LinhVucModel.fromJson(json.decode(str));

String linhVucModelToJson(LinhVucModel data) => json.encode(data.toJson());

@JsonSerializable()
class LinhVucModel {
  @JsonKey(name: "tenLinhVuc")
  String? tenLinhVuc;
  @JsonKey(name: "moTa")
  String? moTa;
  @JsonKey(name: "guid")
  String? guid;

  LinhVucModel({
    this.tenLinhVuc,
    this.moTa,
    this.guid,
  });

  LinhVucModel copyWith({
    String? tenLinhVuc,
    String? moTa,
    String? guid,
  }) =>
      LinhVucModel(
        tenLinhVuc: tenLinhVuc ?? this.tenLinhVuc,
        moTa: moTa ?? this.moTa,
        guid: guid ?? this.guid,
      );

  factory LinhVucModel.fromJson(Map<String, dynamic> json) =>
      _$LinhVucModelFromJson(json);

  Map<String, dynamic> toJson() => _$LinhVucModelToJson(this);
}
