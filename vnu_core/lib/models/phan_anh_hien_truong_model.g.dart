// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phan_anh_hien_truong_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhanAnhHienTruongModel _$PhanAnhHienTruongModelFromJson(
        Map<String, dynamic> json) =>
    PhanAnhHienTruongModel(
      guidChuDe: json['guidChuDe'] as String?,
      guidKhuVucBanDo: json['guidKhuVucBanDo'] as String?,
      tieuDePhanAnh: json['tieuDePhanAnh'] as String?,
      diaDiemPhanAnh: json['diaDiemPhanAnh'] as String?,
      mapDiaDiemPhanAnh: json['mapDiaDiemPhanAnh'] as String?,
      noiDungPhanAnh: json['noiDungPhanAnh'] as String?,
      guid: json['guid'] as String?,
      nguoiGui: json['nguoiGui'] as String?,
      maSinhVien: json['maSinhVien'] as String?,
      thoiGianGui: json['thoiGianGui'] == null
          ? null
          : DateTime.parse(json['thoiGianGui'] as String),
      tenChuDe: json['tenChuDe'] as String?,
      fileDinhKemsPhanAnh: (json['fileDinhKemsPhanAnh'] as List<dynamic>?)
          ?.map((e) => FileDinhKemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PhanAnhHienTruongModelToJson(
        PhanAnhHienTruongModel instance) =>
    <String, dynamic>{
      'guidChuDe': instance.guidChuDe,
      'guidKhuVucBanDo': instance.guidKhuVucBanDo,
      'tieuDePhanAnh': instance.tieuDePhanAnh,
      'diaDiemPhanAnh': instance.diaDiemPhanAnh,
      'mapDiaDiemPhanAnh': instance.mapDiaDiemPhanAnh,
      'noiDungPhanAnh': instance.noiDungPhanAnh,
      'guid': instance.guid,
      'nguoiGui': instance.nguoiGui,
      'maSinhVien': instance.maSinhVien,
      'thoiGianGui': instance.thoiGianGui?.toIso8601String(),
      'tenChuDe': instance.tenChuDe,
      'fileDinhKemsPhanAnh': instance.fileDinhKemsPhanAnh,
    };
