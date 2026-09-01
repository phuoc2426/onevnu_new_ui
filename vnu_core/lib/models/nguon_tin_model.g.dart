// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nguon_tin_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NguonTinModel _$NguonTinModelFromJson(Map<String, dynamic> json) =>
    NguonTinModel(
      guid: json['guid'] as String?,
      tieuDe: json['tieuDe'] as String?,
      linkLienKet: json['linkLienKet'] as String?,
      guidFileLogoNguonTins: (json['guidFileLogoNguonTins'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      thuTu: (json['thuTu'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NguonTinModelToJson(NguonTinModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'tieuDe': instance.tieuDe,
      'linkLienKet': instance.linkLienKet,
      'guidFileLogoNguonTins': instance.guidFileLogoNguonTins,
      'thuTu': instance.thuTu,
    };
