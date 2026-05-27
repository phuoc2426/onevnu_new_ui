// To parse this JSON data, do
//
//     final phanAnhHienTruongXuLyModel = phanAnhHienTruongXuLyModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'file_dinh_kem_model.dart';

part 'phan_anh_hien_truong_xu_ly_model.g.dart';

PhanAnhHienTruongXuLyModel phanAnhHienTruongXuLyModelFromJson(String str) =>
    PhanAnhHienTruongXuLyModel.fromJson(json.decode(str));

String phanAnhHienTruongXuLyModelToJson(PhanAnhHienTruongXuLyModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class PhanAnhHienTruongXuLyModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tieuDePhanAnh")
  String? tieuDePhanAnh;
  @JsonKey(name: "tenChuDe")
  String? tenChuDe;
  @JsonKey(name: "thoiGianGui")
  DateTime? thoiGianGui;
  @JsonKey(name: "tenKhuVuc")
  String? tenKhuVuc;
  @JsonKey(name: "guidKhuVucBanDo")
  String? guidKhuVucBanDo;
  @JsonKey(name: "diaDiemPhanAnh")
  String? diaDiemPhanAnh;
  @JsonKey(name: "mapDiaDiemPhanAnh")
  String? mapDiaDiemPhanAnh;
  @JsonKey(name: "noiDungPhanAnh")
  String? noiDungPhanAnh;
  // @JsonKey(name: "guidFileDinhKemsPhanAnh")
  // List<String>? guidFileDinhKemsPhanAnh;
  @JsonKey(name: "guidChuDe")
  String? guidChuDe;
  // @JsonKey(name: "tenFileDinhKemsPhanAnh")
  // List<String>? tenFileDinhKemsPhanAnh;
  @JsonKey(name: "tenNguoiTraLoi")
  String? tenNguoiTraLoi;
  @JsonKey(name: "thoiGianTraLoi")
  DateTime? thoiGianTraLoi;
  // @JsonKey(name: "tenFileDinhKemsXuLy")
  // List<String>? tenFileDinhKemsXuLy;
  // @JsonKey(name: "guidFileDinhKemsXuLy")
  // List<String>? guidFileDinhKemsXuLy;
  @JsonKey(name: "noiDungXuLy")
  String? noiDungXuLy;

  @JsonKey(name: "fileDinhKemsPhanAnh")
  List<FileDinhKemModel>? fileDinhKemsPhanAnh;

  @JsonKey(name: "fileDinhKemsXuLy")
  List<FileDinhKemModel>? fileDinhKemsXuLy;

  PhanAnhHienTruongXuLyModel({
    this.guid,
    this.tieuDePhanAnh,
    this.tenChuDe,
    this.thoiGianGui,
    this.tenKhuVuc,
    this.guidKhuVucBanDo,
    this.diaDiemPhanAnh,
    this.mapDiaDiemPhanAnh,
    this.noiDungPhanAnh,
    // this.guidFileDinhKemsPhanAnh,
    this.guidChuDe,
    // this.tenFileDinhKemsPhanAnh,
    this.tenNguoiTraLoi,
    this.thoiGianTraLoi,
    // this.tenFileDinhKemsXuLy,
    // this.guidFileDinhKemsXuLy,
    this.fileDinhKemsPhanAnh,
    this.fileDinhKemsXuLy,
    this.noiDungXuLy,
  });

  PhanAnhHienTruongXuLyModel copyWith({
    String? guid,
    String? tieuDePhanAnh,
    String? tenChuDe,
    DateTime? thoiGianGui,
    String? tenKhuVuc,
    String? guidKhuVucBanDo,
    String? diaDiemPhanAnh,
    String? mapDiaDiemPhanAnh,
    String? noiDungPhanAnh,
    // List<String>? guidFileDinhKemsPhanAnh,
    String? guidChuDe,
    // List<String>? tenFileDinhKemsPhanAnh,
    String? tenNguoiTraLoi,
    DateTime? thoiGianTraLoi,
    // List<String>? tenFileDinhKemsXuLy,
    // List<String>? guidFileDinhKemsXuLy,
    List<FileDinhKemModel>? fileDinhKemsPhanAnh,
    List<FileDinhKemModel>? fileDinhKemsXuLy,
    String? noiDungXuLy,
  }) =>
      PhanAnhHienTruongXuLyModel(
        guid: guid ?? this.guid,
        tieuDePhanAnh: tieuDePhanAnh ?? this.tieuDePhanAnh,
        tenChuDe: tenChuDe ?? this.tenChuDe,
        thoiGianGui: thoiGianGui ?? this.thoiGianGui,
        tenKhuVuc: tenKhuVuc ?? this.tenKhuVuc,
        guidKhuVucBanDo: guidKhuVucBanDo ?? this.guidKhuVucBanDo,
        diaDiemPhanAnh: diaDiemPhanAnh ?? this.diaDiemPhanAnh,
        mapDiaDiemPhanAnh: mapDiaDiemPhanAnh ?? this.mapDiaDiemPhanAnh,
        noiDungPhanAnh: noiDungPhanAnh ?? this.noiDungPhanAnh,
        // guidFileDinhKemsPhanAnh:
        //     guidFileDinhKemsPhanAnh ?? this.guidFileDinhKemsPhanAnh,
        guidChuDe: guidChuDe ?? this.guidChuDe,
        // tenFileDinhKemsPhanAnh:
        //     tenFileDinhKemsPhanAnh ?? this.tenFileDinhKemsPhanAnh,
        tenNguoiTraLoi: tenNguoiTraLoi ?? this.tenNguoiTraLoi,
        thoiGianTraLoi: thoiGianTraLoi ?? this.thoiGianTraLoi,
        // tenFileDinhKemsXuLy: tenFileDinhKemsXuLy ?? this.tenFileDinhKemsXuLy,
        // guidFileDinhKemsXuLy: guidFileDinhKemsXuLy ?? this.guidFileDinhKemsXuLy,
        fileDinhKemsPhanAnh: fileDinhKemsPhanAnh ?? this.fileDinhKemsPhanAnh,
        fileDinhKemsXuLy: fileDinhKemsXuLy ?? this.fileDinhKemsXuLy,
        noiDungXuLy: noiDungXuLy ?? this.noiDungXuLy,
      );

  factory PhanAnhHienTruongXuLyModel.fromJson(Map<String, dynamic> json) =>
      _$PhanAnhHienTruongXuLyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhanAnhHienTruongXuLyModelToJson(this);
}
