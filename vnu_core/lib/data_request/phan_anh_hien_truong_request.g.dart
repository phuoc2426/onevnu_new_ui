// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phan_anh_hien_truong_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhanAnhHienTruongRequest _$PhanAnhHienTruongRequestFromJson(
        Map<String, dynamic> json) =>
    PhanAnhHienTruongRequest(
      guidChuDe: json['guidChuDe'] as String,
      guidKhuVucBanDo: json['guidKhuVucBanDo'] as String,
      tieuDePhanAnh: json['tieuDePhanAnh'] as String,
      diaDiemPhanAnh: json['diaDiemPhanAnh'] as String,
      mapDiaDiemPhanAnh: json['mapDiaDiemPhanAnh'] as String?,
      noiDungPhanAnh: json['noiDungPhanAnh'] as String,
      guidFileDinhKemsPhanAnh:
          (json['guidFileDinhKemsPhanAnh'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$PhanAnhHienTruongRequestToJson(
        PhanAnhHienTruongRequest instance) =>
    <String, dynamic>{
      'guidChuDe': instance.guidChuDe,
      'guidKhuVucBanDo': instance.guidKhuVucBanDo,
      'tieuDePhanAnh': instance.tieuDePhanAnh,
      'diaDiemPhanAnh': instance.diaDiemPhanAnh,
      'mapDiaDiemPhanAnh': instance.mapDiaDiemPhanAnh,
      'noiDungPhanAnh': instance.noiDungPhanAnh,
      'guidFileDinhKemsPhanAnh': instance.guidFileDinhKemsPhanAnh,
    };
