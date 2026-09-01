// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tin_he_thong_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TinHeThongModel _$TinHeThongModelFromJson(Map<String, dynamic> json) =>
    TinHeThongModel(
      guid: json['guid'] as String?,
      loaiTinHeThong: json['loaiTinHeThong'] as String?,
      tieuDe: json['tieuDe'] as String?,
      noiDung: json['noiDung'] as String?,
      nguonTin: json['nguonTin'] as String?,
      thoiGian: json['thoiGian'] == null
          ? null
          : DateTime.parse(json['thoiGian'] as String),
      guidFileDinhKems: (json['guidFileDinhKems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tenFileDinhKems: (json['tenFileDinhKems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TinHeThongModelToJson(TinHeThongModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'loaiTinHeThong': instance.loaiTinHeThong,
      'tieuDe': instance.tieuDe,
      'noiDung': instance.noiDung,
      'nguonTin': instance.nguonTin,
      'thoiGian': instance.thoiGian?.toIso8601String(),
      'guidFileDinhKems': instance.guidFileDinhKems,
      'tenFileDinhKems': instance.tenFileDinhKems,
    };
