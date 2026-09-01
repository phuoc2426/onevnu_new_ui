// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tin_tuc_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TinTucModel _$TinTucModelFromJson(Map<String, dynamic> json) => TinTucModel(
      guid: json['guid'] as String?,
      tenChuyenMuc: json['tenChuyenMuc'] as String?,
      tieuDe: json['tieuDe'] as String?,
      guidChuyenMucTinTuc: json['guidChuyenMucTinTuc'] as String?,
      guidFileAnhDaiDiens: (json['guidFileAnhDaiDiens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      htmlNoiDungTinBai: json['htmlNoiDungTinBai'] as String?,
      tenFileDinhKem: json['tenFileDinhKem'] as String?,
      guidFileDinhKems: (json['guidFileDinhKems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      donViXuatBan: json['donViXuatBan'] as String?,
      thoiGianTao: json['thoiGianTao'] == null
          ? null
          : DateTime.parse(json['thoiGianTao'] as String),
    );

Map<String, dynamic> _$TinTucModelToJson(TinTucModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'tenChuyenMuc': instance.tenChuyenMuc,
      'tieuDe': instance.tieuDe,
      'guidChuyenMucTinTuc': instance.guidChuyenMucTinTuc,
      'guidFileAnhDaiDiens': instance.guidFileAnhDaiDiens,
      'htmlNoiDungTinBai': instance.htmlNoiDungTinBai,
      'tenFileDinhKem': instance.tenFileDinhKem,
      'guidFileDinhKems': instance.guidFileDinhKems,
      'donViXuatBan': instance.donViXuatBan,
      'thoiGianTao': instance.thoiGianTao?.toIso8601String(),
    };
