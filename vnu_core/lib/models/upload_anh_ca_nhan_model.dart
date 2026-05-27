// To parse this JSON data, do
//
//     final uploadAnhCaNhanModel = uploadAnhCaNhanModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'upload_anh_ca_nhan_model.g.dart';

UploadAnhCaNhanModel uploadAnhCaNhanModelFromJson(String str) =>
    UploadAnhCaNhanModel.fromJson(json.decode(str));

String uploadAnhCaNhanModelToJson(UploadAnhCaNhanModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class UploadAnhCaNhanModel {
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

  UploadAnhCaNhanModel({
    this.guid,
    this.name,
    this.extension,
    this.size,
    this.trangThai,
  });

  UploadAnhCaNhanModel copyWith({
    String? guid,
    String? name,
    String? extension,
    int? size,
    String? trangThai,
  }) =>
      UploadAnhCaNhanModel(
        guid: guid ?? this.guid,
        name: name ?? this.name,
        extension: extension ?? this.extension,
        size: size ?? this.size,
        trangThai: trangThai ?? this.trangThai,
      );

  factory UploadAnhCaNhanModel.fromJson(Map<String, dynamic> json) =>
      _$UploadAnhCaNhanModelFromJson(json);

  Map<String, dynamic> toJson() => _$UploadAnhCaNhanModelToJson(this);
}
