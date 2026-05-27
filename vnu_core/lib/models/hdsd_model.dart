// To parse this JSON data, do
//
//     final hdsdModel = hdsdModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'hdsd_model.g.dart';

HdsdModel hdsdModelFromJson(String str) => HdsdModel.fromJson(json.decode(str));

String hdsdModelToJson(HdsdModel data) => json.encode(data.toJson());

@JsonSerializable()
class HdsdModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "name")
  String? name;
  @JsonKey(name: "extension")
  String? extension;
  @JsonKey(name: "size")
  int? size;
  @JsonKey(name: "trangThai")
  String? trangThai;

  HdsdModel({
    this.guid,
    this.name,
    this.extension,
    this.size,
    this.trangThai,
  });

  HdsdModel copyWith({
    String? guid,
    String? name,
    String? extension,
    int? size,
    String? trangThai,
  }) =>
      HdsdModel(
        guid: guid ?? this.guid,
        name: name ?? this.name,
        extension: extension ?? this.extension,
        size: size ?? this.size,
        trangThai: trangThai ?? this.trangThai,
      );

  factory HdsdModel.fromJson(Map<String, dynamic> json) =>
      _$HdsdModelFromJson(json);

  Map<String, dynamic> toJson() => _$HdsdModelToJson(this);
}
