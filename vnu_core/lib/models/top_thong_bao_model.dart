// To parse this JSON data, do
//
//     final topThongBaoModel = topThongBaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'top_thong_bao_model.g.dart';

TopThongBaoModel topThongBaoModelFromJson(String str) =>
    TopThongBaoModel.fromJson(json.decode(str));

String topThongBaoModelToJson(TopThongBaoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class TopThongBaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "redirectUrl")
  String? redirectUrl;

  TopThongBaoModel({
    this.id,
    this.tieuDe,
    this.redirectUrl,
  });

  TopThongBaoModel copyWith({
    String? id,
    String? tieuDe,
    String? redirectUrl,
  }) =>
      TopThongBaoModel(
        id: id ?? this.id,
        tieuDe: tieuDe ?? this.tieuDe,
        redirectUrl: redirectUrl ?? this.redirectUrl,
      );

  factory TopThongBaoModel.fromJson(Map<String, dynamic> json) =>
      _$TopThongBaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TopThongBaoModelToJson(this);
}
