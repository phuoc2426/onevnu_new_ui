// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_dinh_kem_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileDinhKemModel _$FileDinhKemModelFromJson(Map<String, dynamic> json) =>
    FileDinhKemModel(
      guid: json['guid'] as String?,
      name: json['name'] as String?,
      extension: json['extension'] as String?,
      size: (json['size'] as num?)?.toInt(),
      trangThai: json['trangThai'] as String?,
    );

Map<String, dynamic> _$FileDinhKemModelToJson(FileDinhKemModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'name': instance.name,
      'extension': instance.extension,
      'size': instance.size,
      'trangThai': instance.trangThai,
    };
