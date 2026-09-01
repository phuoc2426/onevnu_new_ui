// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anh_ca_nhan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnhCaNhanModel _$AnhCaNhanModelFromJson(Map<String, dynamic> json) =>
    AnhCaNhanModel(
      guid: json['guid'] as String?,
      name: json['name'] as String?,
      extension: json['extension'] as String?,
      size: (json['size'] as num?)?.toInt(),
      trangThai: json['trangThai'] as String?,
    );

Map<String, dynamic> _$AnhCaNhanModelToJson(AnhCaNhanModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'name': instance.name,
      'extension': instance.extension,
      'size': instance.size,
      'trangThai': instance.trangThai,
    };
