// To parse this JSON data, do
//
//     final tinHeThongModel = tinHeThongModelFromJson(jsonString);

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'tin_he_thong_model.g.dart';

TinHeThongModel tinHeThongModelFromJson(String str) =>
    TinHeThongModel.fromJson(json.decode(str));

String tinHeThongModelToJson(TinHeThongModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class TinHeThongModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "loaiTinHeThong")
  String? loaiTinHeThong;
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "noiDung")
  String? noiDung;
  @JsonKey(name: "nguonTin")
  String? nguonTin;
  @JsonKey(name: "thoiGian")
  DateTime? thoiGian;
  @JsonKey(name: "guidFileDinhKems")
  List<String>? guidFileDinhKems;
  @JsonKey(name: "tenFileDinhKems")
  List<String>? tenFileDinhKems;

  TinHeThongModel({
    this.guid,
    this.loaiTinHeThong,
    this.tieuDe,
    this.noiDung,
    this.nguonTin,
    this.thoiGian,
    this.guidFileDinhKems,
    this.tenFileDinhKems,
  });

  TinHeThongModel copyWith({
    String? guid,
    String? loaiTinHeThong,
    String? tieuDe,
    String? noiDung,
    String? nguonTin,
    DateTime? thoiGian,
    List<String>? guidFileDinhKems,
    List<String>? tenFileDinhKems,
  }) =>
      TinHeThongModel(
        guid: guid ?? this.guid,
        loaiTinHeThong: loaiTinHeThong ?? this.loaiTinHeThong,
        tieuDe: tieuDe ?? this.tieuDe,
        noiDung: noiDung ?? this.noiDung,
        nguonTin: nguonTin ?? this.nguonTin,
        thoiGian: thoiGian ?? this.thoiGian,
        guidFileDinhKems: guidFileDinhKems ?? this.guidFileDinhKems,
        tenFileDinhKems: tenFileDinhKems ?? this.tenFileDinhKems
      );

  factory TinHeThongModel.fromJson(Map<String, dynamic> json) =>
      _$TinHeThongModelFromJson(json);

  Map<String, dynamic> toJson() => _$TinHeThongModelToJson(this);
}
