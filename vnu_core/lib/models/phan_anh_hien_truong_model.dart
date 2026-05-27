// To parse this JSON data, do
//
//     final phanAnhHienTruongModel = phanAnhHienTruongModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/model.dart';

part 'phan_anh_hien_truong_model.g.dart';

PhanAnhHienTruongModel phanAnhHienTruongModelFromJson(String str) =>
    PhanAnhHienTruongModel.fromJson(json.decode(str));

String phanAnhHienTruongModelToJson(PhanAnhHienTruongModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class PhanAnhHienTruongModel {
  @JsonKey(name: "guidChuDe")
  String? guidChuDe;
  @JsonKey(name: "guidKhuVucBanDo")
  String? guidKhuVucBanDo;
  @JsonKey(name: "tieuDePhanAnh")
  String? tieuDePhanAnh;
  @JsonKey(name: "diaDiemPhanAnh")
  String? diaDiemPhanAnh;
  @JsonKey(name: "mapDiaDiemPhanAnh")
  String? mapDiaDiemPhanAnh;
  @JsonKey(name: "noiDungPhanAnh")
  String? noiDungPhanAnh;
  // @JsonKey(name: "guidFileDinhKemsPhanAnh")
  // List<String>? guidFileDinhKemsPhanAnh;
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "nguoiGui")
  String? nguoiGui;
  @JsonKey(name: "maSinhVien")
  String? maSinhVien;
  @JsonKey(name: "thoiGianGui")
  DateTime? thoiGianGui;
  // @JsonKey(name: "tenFileDinhKemsPhanAnh")
  // List<String>? tenFileDinhKemsPhanAnh;
  @JsonKey(name: "tenChuDe")
  String? tenChuDe;

  @JsonKey(name: "fileDinhKemsPhanAnh")
  List<FileDinhKemModel>? fileDinhKemsPhanAnh;

  PhanAnhHienTruongModel(
      {this.guidChuDe,
      this.guidKhuVucBanDo,
      this.tieuDePhanAnh,
      this.diaDiemPhanAnh,
      this.mapDiaDiemPhanAnh,
      this.noiDungPhanAnh,
      // this.guidFileDinhKemsPhanAnh,
      this.guid,
      this.nguoiGui,
      this.maSinhVien,
      this.thoiGianGui,
      // this.tenFileDinhKemsPhanAnh,
      this.tenChuDe,
      this.fileDinhKemsPhanAnh});

  PhanAnhHienTruongModel copyWith({
    String? guidChuDe,
    String? guidKhuVucBanDo,
    String? tieuDePhanAnh,
    String? diaDiemPhanAnh,
    String? mapDiaDiemPhanAnh,
    String? noiDungPhanAnh,
    List<String>? guidFileDinhKemsPhanAnh,
    String? guid,
    String? nguoiGui,
    String? maSinhVien,
    DateTime? thoiGianGui,
    List<String>? tenFileDinhKemsPhanAnh,
    String? tenChuDe,
    List<FileDinhKemModel>? fileDinhKemsPhanAnh,
  }) =>
      PhanAnhHienTruongModel(
        guidChuDe: guidChuDe ?? this.guidChuDe,
        guidKhuVucBanDo: guidKhuVucBanDo ?? this.guidKhuVucBanDo,
        tieuDePhanAnh: tieuDePhanAnh ?? this.tieuDePhanAnh,
        diaDiemPhanAnh: diaDiemPhanAnh ?? this.diaDiemPhanAnh,
        mapDiaDiemPhanAnh: mapDiaDiemPhanAnh ?? this.mapDiaDiemPhanAnh,
        noiDungPhanAnh: noiDungPhanAnh ?? this.noiDungPhanAnh,
        // guidFileDinhKemsPhanAnh:
        //     guidFileDinhKemsPhanAnh ?? this.guidFileDinhKemsPhanAnh,
        guid: guid ?? this.guid,
        nguoiGui: nguoiGui ?? this.nguoiGui,
        maSinhVien: maSinhVien ?? this.maSinhVien,
        thoiGianGui: thoiGianGui ?? this.thoiGianGui,
        // tenFileDinhKemsPhanAnh:
        //     tenFileDinhKemsPhanAnh ?? this.tenFileDinhKemsPhanAnh,
        tenChuDe: tenChuDe ?? this.tenChuDe,
        fileDinhKemsPhanAnh: fileDinhKemsPhanAnh ?? this.fileDinhKemsPhanAnh,
      );

  factory PhanAnhHienTruongModel.fromJson(Map<String, dynamic> json) =>
      _$PhanAnhHienTruongModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhanAnhHienTruongModelToJson(this);

  //Public function

  String? getThumbId() {
    List<FileDinhKemModel> files = fileDinhKemsPhanAnh ?? [];
    if (files.isEmpty) {
      return null;
    }

    for (var element in files) {
      if ((element.name ?? '').isImage()) {
        return element.guid;
      }
    }

    return null;
  }

  bool containtMapLocation() {
    String diadiem = mapDiaDiemPhanAnh ?? '';
    if (diadiem.isNotEmpty && diadiem.contains(',')) {
      return true;
    }
    return false;
  }
}
