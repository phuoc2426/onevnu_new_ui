// To parse this JSON data, do
//
//     final fileDinhKemModel = fileDinhKemModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'file_dinh_kem_model.g.dart';

FileDinhKemModel fileDinhKemModelFromJson(String str) =>
    FileDinhKemModel.fromJson(json.decode(str));

String fileDinhKemModelToJson(FileDinhKemModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class FileDinhKemModel {
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

  FileDinhKemModel({
    this.guid,
    this.name,
    this.extension,
    this.size,
    this.trangThai,
  });

  FileDinhKemModel copyWith({
    String? guid,
    String? name,
    String? extension,
    int? size,
    String? trangThai,
  }) =>
      FileDinhKemModel(
        guid: guid ?? this.guid,
        name: name ?? this.name,
        extension: extension ?? this.extension,
        size: size ?? this.size,
        trangThai: trangThai ?? this.trangThai,
      );

  factory FileDinhKemModel.fromJson(Map<String, dynamic> json) =>
      _$FileDinhKemModelFromJson(json);

  Map<String, dynamic> toJson() => _$FileDinhKemModelToJson(this);
}
