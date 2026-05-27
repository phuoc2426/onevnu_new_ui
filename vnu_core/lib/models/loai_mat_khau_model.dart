// To parse this JSON data, do
//
//     final loaiMatKhauModel = loaiMatKhauModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'loai_mat_khau_model.g.dart';

LoaiMatKhauModel loaiMatKhauModelFromJson(String str) =>
    LoaiMatKhauModel.fromJson(json.decode(str));

String loaiMatKhauModelToJson(LoaiMatKhauModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class LoaiMatKhauModel {
  @JsonKey(name: "key")
  String? key;
  @JsonKey(name: "label")
  String? label;

  LoaiMatKhauModel({
    this.key,
    this.label,
  });

  LoaiMatKhauModel copyWith({
    String? key,
    String? label,
  }) =>
      LoaiMatKhauModel(
        key: key ?? this.key,
        label: label ?? this.label,
      );

  factory LoaiMatKhauModel.fromJson(Map<String, dynamic> json) =>
      _$LoaiMatKhauModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoaiMatKhauModelToJson(this);
}
