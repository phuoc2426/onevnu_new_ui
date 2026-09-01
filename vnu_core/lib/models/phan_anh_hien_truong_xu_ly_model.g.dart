// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phan_anh_hien_truong_xu_ly_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhanAnhHienTruongXuLyModel _$PhanAnhHienTruongXuLyModelFromJson(
        Map<String, dynamic> json) =>
    PhanAnhHienTruongXuLyModel(
      guid: json['guid'] as String?,
      tieuDePhanAnh: json['tieuDePhanAnh'] as String?,
      tenChuDe: json['tenChuDe'] as String?,
      thoiGianGui: json['thoiGianGui'] == null
          ? null
          : DateTime.parse(json['thoiGianGui'] as String),
      tenKhuVuc: json['tenKhuVuc'] as String?,
      guidKhuVucBanDo: json['guidKhuVucBanDo'] as String?,
      diaDiemPhanAnh: json['diaDiemPhanAnh'] as String?,
      mapDiaDiemPhanAnh: json['mapDiaDiemPhanAnh'] as String?,
      noiDungPhanAnh: json['noiDungPhanAnh'] as String?,
      guidChuDe: json['guidChuDe'] as String?,
      tenNguoiTraLoi: json['tenNguoiTraLoi'] as String?,
      thoiGianTraLoi: json['thoiGianTraLoi'] == null
          ? null
          : DateTime.parse(json['thoiGianTraLoi'] as String),
      fileDinhKemsPhanAnh: (json['fileDinhKemsPhanAnh'] as List<dynamic>?)
          ?.map((e) => FileDinhKemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      fileDinhKemsXuLy: (json['fileDinhKemsXuLy'] as List<dynamic>?)
          ?.map((e) => FileDinhKemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      noiDungXuLy: json['noiDungXuLy'] as String?,
    );

Map<String, dynamic> _$PhanAnhHienTruongXuLyModelToJson(
        PhanAnhHienTruongXuLyModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'tieuDePhanAnh': instance.tieuDePhanAnh,
      'tenChuDe': instance.tenChuDe,
      'thoiGianGui': instance.thoiGianGui?.toIso8601String(),
      'tenKhuVuc': instance.tenKhuVuc,
      'guidKhuVucBanDo': instance.guidKhuVucBanDo,
      'diaDiemPhanAnh': instance.diaDiemPhanAnh,
      'mapDiaDiemPhanAnh': instance.mapDiaDiemPhanAnh,
      'noiDungPhanAnh': instance.noiDungPhanAnh,
      'guidChuDe': instance.guidChuDe,
      'tenNguoiTraLoi': instance.tenNguoiTraLoi,
      'thoiGianTraLoi': instance.thoiGianTraLoi?.toIso8601String(),
      'noiDungXuLy': instance.noiDungXuLy,
      'fileDinhKemsPhanAnh': instance.fileDinhKemsPhanAnh,
      'fileDinhKemsXuLy': instance.fileDinhKemsXuLy,
    };
