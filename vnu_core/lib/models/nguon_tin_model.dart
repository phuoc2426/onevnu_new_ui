// To parse this JSON data, do
//
//     final nguonTinModel = nguonTinModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'nguon_tin_model.g.dart';

NguonTinModel nguonTinModelFromJson(String str) =>
    NguonTinModel.fromJson(json.decode(str));

String nguonTinModelToJson(NguonTinModel data) => json.encode(data.toJson());

@JsonSerializable()
class NguonTinModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "linkLienKet")
  String? linkLienKet;
  @JsonKey(name: "guidFileLogoNguonTins")
  List<String>? guidFileLogoNguonTins;
  @JsonKey(name: "thuTu")
  int thuTu;

  NguonTinModel({
    this.guid,
    this.tieuDe,
    this.linkLienKet,
    this.guidFileLogoNguonTins,
    this.thuTu = 0,
  });

  NguonTinModel copyWith({
    String? guid,
    String? tieuDe,
    String? linkLienKet,
    List<String>? guidFileLogoNguonTins,
    int? thuTu,
  }) =>
      NguonTinModel(
        guid: guid ?? this.guid,
        tieuDe: tieuDe ?? this.tieuDe,
        linkLienKet: linkLienKet ?? this.linkLienKet,
        guidFileLogoNguonTins:
            guidFileLogoNguonTins ?? this.guidFileLogoNguonTins,
        thuTu: thuTu ?? this.thuTu,
      );

  factory NguonTinModel.fromJson(Map<String, dynamic> json) =>
      _$NguonTinModelFromJson(json);

  Map<String, dynamic> toJson() => _$NguonTinModelToJson(this);
}
