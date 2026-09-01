// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cam_nang_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CamNangModel _$CamNangModelFromJson(Map<String, dynamic> json) => CamNangModel(
      guid: json['guid'] as String?,
      tenFileCamNang: json['tenFileCamNang'] as String?,
      tenChuyenMuc: json['tenChuyenMuc'] as String?,
      tieuDe: json['tieuDe'] as String?,
      guidChuyenMucCamNang: json['guidChuyenMucCamNang'] as String?,
      tomTat: json['tomTat'] as String?,
      guidFileAnhDaiDiens: (json['guidFileAnhDaiDiens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      guidFileCamNangs: (json['guidFileCamNangs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      donViXuatBan: json['donViXuatBan'] as String?,
      thoiGianTao: json['thoiGianTao'] == null
          ? null
          : DateTime.parse(json['thoiGianTao'] as String),
    );

Map<String, dynamic> _$CamNangModelToJson(CamNangModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'tenFileCamNang': instance.tenFileCamNang,
      'tenChuyenMuc': instance.tenChuyenMuc,
      'tieuDe': instance.tieuDe,
      'guidChuyenMucCamNang': instance.guidChuyenMucCamNang,
      'tomTat': instance.tomTat,
      'guidFileAnhDaiDiens': instance.guidFileAnhDaiDiens,
      'guidFileCamNangs': instance.guidFileCamNangs,
      'donViXuatBan': instance.donViXuatBan,
      'thoiGianTao': instance.thoiGianTao?.toIso8601String(),
    };
