// To parse this JSON data, do
//
//     final topTinTucDetailModel = topTinTucDetailModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'top_tin_tuc_detail_model.g.dart';

TopTinTucDetailModel topTinTucDetailModelFromJson(String str) =>
    TopTinTucDetailModel.fromJson(json.decode(str));

String topTinTucDetailModelToJson(TopTinTucDetailModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class TopTinTucDetailModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "noiDung")
  String? noiDung;
  @JsonKey(name: "tacGia")
  String? tacGia;
  @JsonKey(name: "nguonTin")
  String? nguonTin;

  TopTinTucDetailModel({
    this.id,
    this.tieuDe,
    this.noiDung,
    this.tacGia,
    this.nguonTin,
  });

  TopTinTucDetailModel copyWith({
    String? id,
    String? tieuDe,
    String? noiDung,
    String? tacGia,
    String? nguonTin,
  }) =>
      TopTinTucDetailModel(
        id: id ?? this.id,
        tieuDe: tieuDe ?? this.tieuDe,
        noiDung: noiDung ?? this.noiDung,
        tacGia: tacGia ?? this.tacGia,
        nguonTin: nguonTin ?? this.nguonTin,
      );

  factory TopTinTucDetailModel.fromJson(Map<String, dynamic> json) =>
      _$TopTinTucDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$TopTinTucDetailModelToJson(this);
}
