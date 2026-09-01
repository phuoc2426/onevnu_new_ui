// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hdsd_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HdsdModel _$HdsdModelFromJson(Map<String, dynamic> json) => HdsdModel(
      guid: json['guid'] as String?,
      name: json['name'] as String?,
      extension: json['extension'] as String?,
      size: (json['size'] as num?)?.toInt(),
      trangThai: json['trangThai'] as String?,
    );

Map<String, dynamic> _$HdsdModelToJson(HdsdModel instance) => <String, dynamic>{
      'guid': instance.guid,
      'name': instance.name,
      'extension': instance.extension,
      'size': instance.size,
      'trangThai': instance.trangThai,
    };
