// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lien_ket_danh_dau_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LienKetDanhDauModel _$LienKetDanhDauModelFromJson(Map<String, dynamic> json) =>
    LienKetDanhDauModel(
      lienKet: json['lienKet'] as String?,
      tenLienKet: json['tenLienKet'] as String?,
      guid: json['guid'] as String?,
    );

Map<String, dynamic> _$LienKetDanhDauModelToJson(
        LienKetDanhDauModel instance) =>
    <String, dynamic>{
      'lienKet': instance.lienKet,
      'tenLienKet': instance.tenLienKet,
      'guid': instance.guid,
    };
