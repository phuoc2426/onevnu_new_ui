// To parse this JSON data, do
//
//     final hoiDapModel = hoiDapModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'hoi_dap_model.g.dart';

HoiDapModel hoiDapModelFromJson(String str) =>
    HoiDapModel.fromJson(json.decode(str));

String hoiDapModelToJson(HoiDapModel data) => json.encode(data.toJson());

@JsonSerializable()
class HoiDapModel {
  @JsonKey(name: "guidChuDe")
  String? guidChuDe;
  @JsonKey(name: "cauHoi")
  String? cauHoi;
  @JsonKey(name: "guidFileDinhKems")
  List<String>? guidFileDinhKems;
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "nguoiGui")
  String? nguoiGui;
  @JsonKey(name: "maSinhVien")
  String? maSinhVien;
  @JsonKey(name: "thoiGianGui")
  DateTime? thoiGianGui;
  @JsonKey(name: "tenFileDinhKem")
  dynamic tenFileDinhKem;
  @JsonKey(name: "tenChuDe")
  String? tenChuDe;

  HoiDapModel({
    this.guidChuDe,
    this.cauHoi,
    this.guidFileDinhKems,
    this.guid,
    this.nguoiGui,
    this.maSinhVien,
    this.thoiGianGui,
    this.tenFileDinhKem,
    this.tenChuDe,
  });

  HoiDapModel copyWith({
    String? guidChuDe,
    String? cauHoi,
    List<String>? guidFileDinhKems,
    String? guid,
    String? nguoiGui,
    String? maSinhVien,
    DateTime? thoiGianGui,
    dynamic tenFileDinhKem,
    String? tenChuDe,
  }) =>
      HoiDapModel(
        guidChuDe: guidChuDe ?? this.guidChuDe,
        cauHoi: cauHoi ?? this.cauHoi,
        guidFileDinhKems: guidFileDinhKems ?? this.guidFileDinhKems,
        guid: guid ?? this.guid,
        nguoiGui: nguoiGui ?? this.nguoiGui,
        maSinhVien: maSinhVien ?? this.maSinhVien,
        thoiGianGui: thoiGianGui ?? this.thoiGianGui,
        tenFileDinhKem: tenFileDinhKem ?? this.tenFileDinhKem,
        tenChuDe: tenChuDe ?? this.tenChuDe,
      );

  factory HoiDapModel.fromJson(Map<String, dynamic> json) =>
      _$HoiDapModelFromJson(json);

  Map<String, dynamic> toJson() => _$HoiDapModelToJson(this);
}
