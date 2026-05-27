// To parse this JSON data, do
//
//     final phanAnhHienTruongRequest = phanAnhHienTruongRequestFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'phan_anh_hien_truong_request.g.dart';

PhanAnhHienTruongRequest phanAnhHienTruongRequestFromJson(String str) =>
    PhanAnhHienTruongRequest.fromJson(json.decode(str));

String phanAnhHienTruongRequestToJson(PhanAnhHienTruongRequest data) =>
    json.encode(data.toJson());

@JsonSerializable()
class PhanAnhHienTruongRequest {
  @JsonKey(name: "guidChuDe")
  String guidChuDe;
  @JsonKey(name: "guidKhuVucBanDo")
  String guidKhuVucBanDo;
  @JsonKey(name: "tieuDePhanAnh")
  String tieuDePhanAnh;
  @JsonKey(name: "diaDiemPhanAnh")
  String diaDiemPhanAnh;
  @JsonKey(name: "mapDiaDiemPhanAnh")
  String? mapDiaDiemPhanAnh;
  @JsonKey(name: "noiDungPhanAnh")
  String noiDungPhanAnh;
  @JsonKey(name: "guidFileDinhKemsPhanAnh")
  List<String> guidFileDinhKemsPhanAnh;

  PhanAnhHienTruongRequest({
    required this.guidChuDe,
    required this.guidKhuVucBanDo,
    required this.tieuDePhanAnh,
    required this.diaDiemPhanAnh,
    required this.mapDiaDiemPhanAnh,
    required this.noiDungPhanAnh,
    required this.guidFileDinhKemsPhanAnh,
  });

  PhanAnhHienTruongRequest copyWith({
    String? guidChuDe,
    String? guidKhuVucBanDo,
    String? tieuDePhanAnh,
    String? diaDiemPhanAnh,
    String? mapDiaDiemPhanAnh,
    String? noiDungPhanAnh,
    List<String>? guidFileDinhKemsPhanAnh,
  }) =>
      PhanAnhHienTruongRequest(
        guidChuDe: guidChuDe ?? this.guidChuDe,
        guidKhuVucBanDo: guidKhuVucBanDo ?? this.guidKhuVucBanDo,
        tieuDePhanAnh: tieuDePhanAnh ?? this.tieuDePhanAnh,
        diaDiemPhanAnh: diaDiemPhanAnh ?? this.diaDiemPhanAnh,
        mapDiaDiemPhanAnh: mapDiaDiemPhanAnh ?? this.mapDiaDiemPhanAnh,
        noiDungPhanAnh: noiDungPhanAnh ?? this.noiDungPhanAnh,
        guidFileDinhKemsPhanAnh:
            guidFileDinhKemsPhanAnh ?? this.guidFileDinhKemsPhanAnh,
      );

  factory PhanAnhHienTruongRequest.fromJson(Map<String, dynamic> json) =>
      _$PhanAnhHienTruongRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PhanAnhHienTruongRequestToJson(this);
}
