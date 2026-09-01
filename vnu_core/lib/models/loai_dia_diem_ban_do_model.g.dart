// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loai_dia_diem_ban_do_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoaiDiaDiemBanDoModel _$LoaiDiaDiemBanDoModelFromJson(
        Map<String, dynamic> json) =>
    LoaiDiaDiemBanDoModel(
      icon: json['icon'] as String?,
      tenLoaiDiaDiemBanDo: json['tenLoaiDiaDiemBanDo'] as String?,
      thuTu: (json['thuTu'] as num?)?.toInt(),
      guid: json['guid'] as String?,
    );

Map<String, dynamic> _$LoaiDiaDiemBanDoModelToJson(
        LoaiDiaDiemBanDoModel instance) =>
    <String, dynamic>{
      'icon': instance.icon,
      'tenLoaiDiaDiemBanDo': instance.tenLoaiDiaDiemBanDo,
      'thuTu': instance.thuTu,
      'guid': instance.guid,
    };
