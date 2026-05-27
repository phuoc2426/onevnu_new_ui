// To parse this JSON data, do
//
//     final thongBaoDaoTaoModel = thongBaoDaoTaoModelFromJson(jsonString);

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'thong_bao_dao_tao_model.g.dart';

ThongBaoDaoTaoModel thongBaoDaoTaoModelFromJson(String str) =>
    ThongBaoDaoTaoModel.fromJson(json.decode(str));

String thongBaoDaoTaoModelToJson(ThongBaoDaoTaoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class ThongBaoDaoTaoModel {
  @JsonKey(name: "noiDung")
  String? noiDung;

  @JsonKey(name: "tieuDe")
  String? tieuDe;

  ThongBaoDaoTaoModel({
    this.noiDung,
    this.tieuDe
  });

  ThongBaoDaoTaoModel copyWith({
    String? noiDung,
    String? tieuDe,
  }) =>
      ThongBaoDaoTaoModel(
        noiDung: noiDung ?? this.noiDung,
        tieuDe: tieuDe ?? this.tieuDe,
      );

  factory ThongBaoDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$ThongBaoDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ThongBaoDaoTaoModelToJson(this);
}
