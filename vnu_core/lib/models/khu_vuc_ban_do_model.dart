// To parse this JSON data, do
//
//     final khuVucBanDoModel = khuVucBanDoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'khu_vuc_ban_do_model.g.dart';

KhuVucBanDoModel khuVucBanDoModelFromJson(String str) =>
    KhuVucBanDoModel.fromJson(json.decode(str));

String khuVucBanDoModelToJson(KhuVucBanDoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class KhuVucBanDoModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenKhuVucBanDo")
  String? tenKhuVucBanDo;
  @JsonKey(name: "kinhDoViDo")
  String? kinhDoViDo;

  KhuVucBanDoModel({
    this.guid,
    this.tenKhuVucBanDo,
    this.kinhDoViDo,
  });

  KhuVucBanDoModel copyWith({
    String? guid,
    String? tenKhuVucBanDo,
    String? kinhDoViDo,
  }) =>
      KhuVucBanDoModel(
        guid: guid ?? this.guid,
        tenKhuVucBanDo: tenKhuVucBanDo ?? this.tenKhuVucBanDo,
        kinhDoViDo: kinhDoViDo ?? this.kinhDoViDo,
      );

  factory KhuVucBanDoModel.fromJson(Map<String, dynamic> json) =>
      _$KhuVucBanDoModelFromJson(json);

  Map<String, dynamic> toJson() => _$KhuVucBanDoModelToJson(this);
}
