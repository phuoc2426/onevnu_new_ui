// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_tin_tuc_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopTinTucModel _$TopTinTucModelFromJson(Map<String, dynamic> json) =>
    TopTinTucModel(
      id: json['id'] as String?,
      anhDaiDien: json['anhDaiDien'] as String?,
      tieuDe: json['tieuDe'] as String?,
      tomTat: json['tomTat'] as String?,
      redirectUrl: json['redirectUrl'] as String?,
    );

Map<String, dynamic> _$TopTinTucModelToJson(TopTinTucModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'anhDaiDien': instance.anhDaiDien,
      'tieuDe': instance.tieuDe,
      'tomTat': instance.tomTat,
      'redirectUrl': instance.redirectUrl,
    };
