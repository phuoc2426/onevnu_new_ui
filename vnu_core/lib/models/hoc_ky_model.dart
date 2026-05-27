// To parse this JSON data, do
//
//     final hocKyModel = hocKyModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'hoc_ky_model.g.dart';

HocKyModel hocKyModelFromJson(String str) =>
    HocKyModel.fromJson(json.decode(str));

String hocKyModelToJson(HocKyModel data) => json.encode(data.toJson());

@JsonSerializable()
class HocKyModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "nam")
  String? nam;

  HocKyModel({
    this.id,
    this.ten,
    this.nam,
  });

  String disPlayName() {
    return 'Kỳ $ten năm $nam';
  }

  HocKyModel copyWith({
    String? id,
    String? ten,
    String? nam,
  }) =>
      HocKyModel(
        id: id ?? this.id,
        ten: ten ?? this.ten,
        nam: nam ?? this.nam,
      );

  factory HocKyModel.fromJson(Map<String, dynamic> json) =>
      _$HocKyModelFromJson(json);

  Map<String, dynamic> toJson() => _$HocKyModelToJson(this);
}
