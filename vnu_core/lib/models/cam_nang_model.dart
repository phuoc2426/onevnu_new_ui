// To parse this JSON data, do
//
//     final camNangModel = camNangModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'cam_nang_model.g.dart';

CamNangModel camNangModelFromJson(String str) =>
    CamNangModel.fromJson(json.decode(str));

String camNangModelToJson(CamNangModel data) => json.encode(data.toJson());

@JsonSerializable()
class CamNangModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenFileCamNang")
  String? tenFileCamNang;
  @JsonKey(name: "tenChuyenMuc")
  String? tenChuyenMuc;
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "guidChuyenMucCamNang")
  String? guidChuyenMucCamNang;
  @JsonKey(name: "tomTat")
  String? tomTat;
  @JsonKey(name: "guidFileAnhDaiDiens")
  List<String>? guidFileAnhDaiDiens;
  @JsonKey(name: "guidFileCamNangs")
  List<String>? guidFileCamNangs;
  @JsonKey(name: "donViXuatBan")
  String? donViXuatBan;
  @JsonKey(name: "thoiGianTao")
  DateTime? thoiGianTao;

  CamNangModel({
    this.guid,
    this.tenFileCamNang,
    this.tenChuyenMuc,
    this.tieuDe,
    this.guidChuyenMucCamNang,
    this.tomTat,
    this.guidFileAnhDaiDiens,
    this.guidFileCamNangs,
    this.donViXuatBan,
    this.thoiGianTao,
  });

  CamNangModel copyWith({
    String? guid,
    String? tenFileCamNang,
    String? tenChuyenMuc,
    String? tieuDe,
    String? guidChuyenMucCamNang,
    String? tomTat,
    List<String>? guidFileAnhDaiDiens,
    List<String>? guidFileCamNangs,
    String? donViXuatBan,
    DateTime? thoiGianTao,
  }) =>
      CamNangModel(
        guid: guid ?? this.guid,
        tenFileCamNang: tenFileCamNang ?? this.tenFileCamNang,
        tenChuyenMuc: tenChuyenMuc ?? this.tenChuyenMuc,
        tieuDe: tieuDe ?? this.tieuDe,
        guidChuyenMucCamNang: guidChuyenMucCamNang ?? this.guidChuyenMucCamNang,
        tomTat: tomTat ?? this.tomTat,
        guidFileAnhDaiDiens: guidFileAnhDaiDiens ?? this.guidFileAnhDaiDiens,
        guidFileCamNangs: guidFileCamNangs ?? this.guidFileCamNangs,
        donViXuatBan: donViXuatBan ?? this.donViXuatBan,
        thoiGianTao: thoiGianTao ?? this.thoiGianTao,
      );

  factory CamNangModel.fromJson(Map<String, dynamic> json) =>
      _$CamNangModelFromJson(json);

  Map<String, dynamic> toJson() => _$CamNangModelToJson(this);
}
