// To parse this JSON data, do
//
//     final topTinTucModel = topTinTucModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'top_tin_tuc_model.g.dart';

TopTinTucModel topTinTucModelFromJson(String str) =>
    TopTinTucModel.fromJson(json.decode(str));

String topTinTucModelToJson(TopTinTucModel data) => json.encode(data.toJson());

@JsonSerializable()
class TopTinTucModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "anhDaiDien")
  String? anhDaiDien;
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "tomTat")
  String? tomTat;
  @JsonKey(name: "redirectUrl")
  String? redirectUrl;

  TopTinTucModel({
    this.id,
    this.anhDaiDien,
    this.tieuDe,
    this.tomTat,
    this.redirectUrl
  });

  TopTinTucModel copyWith({
    String? id,
    String? anhDaiDien,
    String? tieuDe,
    String? tomTat,
    String ? redirectUrl,
  }) =>
      TopTinTucModel(
        id: id ?? this.id,
        anhDaiDien: anhDaiDien ?? this.anhDaiDien,
        tieuDe: tieuDe ?? this.tieuDe,
        tomTat: tomTat ?? this.tomTat,
        redirectUrl: redirectUrl??this.redirectUrl,
      );

  factory TopTinTucModel.fromJson(Map<String, dynamic> json) =>
      _$TopTinTucModelFromJson(json);

  Map<String, dynamic> toJson() => _$TopTinTucModelToJson(this);
}
