// To parse this JSON data, do
//
//     final anhCaNhanModel = anhCaNhanModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'anh_ca_nhan_model.g.dart';

AnhCaNhanModel anhCaNhanModelFromJson(String str) =>
    AnhCaNhanModel.fromJson(json.decode(str));

String anhCaNhanModelToJson(AnhCaNhanModel data) => json.encode(data.toJson());

@JsonSerializable()
class AnhCaNhanModel {
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

  AnhCaNhanModel({
    this.guid,
    this.name,
    this.extension,
    this.size,
    this.trangThai,
  });

  AnhCaNhanModel copyWith({
    String? guid,
    String? name,
    String? extension,
    int? size,
    String? trangThai,
  }) =>
      AnhCaNhanModel(
        guid: guid ?? this.guid,
        name: name ?? this.name,
        extension: extension ?? this.extension,
        size: size ?? this.size,
        trangThai: trangThai ?? this.trangThai,
      );

  factory AnhCaNhanModel.fromJson(Map<String, dynamic> json) =>
      _$AnhCaNhanModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnhCaNhanModelToJson(this);
}
