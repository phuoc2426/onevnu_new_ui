// To parse this JSON data, do
//
//     final tinTucModel = tinTucModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'tin_tuc_model.g.dart';

TinTucModel tinTucModelFromJson(String str) =>
    TinTucModel.fromJson(json.decode(str));

String tinTucModelToJson(TinTucModel data) => json.encode(data.toJson());

@JsonSerializable()
class TinTucModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenChuyenMuc")
  String? tenChuyenMuc;
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "guidChuyenMucTinTuc")
  String? guidChuyenMucTinTuc;
  @JsonKey(name: "guidFileAnhDaiDiens")
  List<String>? guidFileAnhDaiDiens;
  @JsonKey(name: "htmlNoiDungTinBai")
  String? htmlNoiDungTinBai;
  @JsonKey(name: "tenFileDinhKem")
  String? tenFileDinhKem;
  @JsonKey(name: "guidFileDinhKems")
  List<String>? guidFileDinhKems;
  @JsonKey(name: "donViXuatBan")
  String? donViXuatBan;
  @JsonKey(name: "thoiGianTao")
  DateTime? thoiGianTao;

  TinTucModel({
    this.guid,
    this.tenChuyenMuc,
    this.tieuDe,
    this.guidChuyenMucTinTuc,
    this.guidFileAnhDaiDiens,
    this.htmlNoiDungTinBai,
    this.tenFileDinhKem,
    this.guidFileDinhKems,
    this.donViXuatBan,
    this.thoiGianTao,
  });

  TinTucModel copyWith({
    String? guid,
    String? tenChuyenMuc,
    String? tieuDe,
    String? guidChuyenMucTinTuc,
    List<String>? guidFileAnhDaiDiens,
    String? htmlNoiDungTinBai,
    String? tenFileDinhKem,
    List<String>? guidFileDinhKems,
    String? donViXuatBan,
    DateTime? thoiGianTao,
  }) =>
      TinTucModel(
        guid: guid ?? this.guid,
        tenChuyenMuc: tenChuyenMuc ?? this.tenChuyenMuc,
        tieuDe: tieuDe ?? this.tieuDe,
        guidChuyenMucTinTuc: guidChuyenMucTinTuc ?? this.guidChuyenMucTinTuc,
        guidFileAnhDaiDiens: guidFileAnhDaiDiens ?? this.guidFileAnhDaiDiens,
        htmlNoiDungTinBai: htmlNoiDungTinBai ?? this.htmlNoiDungTinBai,
        tenFileDinhKem: tenFileDinhKem ?? this.tenFileDinhKem,
        guidFileDinhKems: guidFileDinhKems ?? this.guidFileDinhKems,
        donViXuatBan: donViXuatBan ?? this.donViXuatBan,
        thoiGianTao: thoiGianTao ?? this.thoiGianTao,
      );

  factory TinTucModel.fromJson(Map<String, dynamic> json) =>
      _$TinTucModelFromJson(json);

  Map<String, dynamic> toJson() => _$TinTucModelToJson(this);
}
