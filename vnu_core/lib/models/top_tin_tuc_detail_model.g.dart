// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_tin_tuc_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopTinTucDetailModel _$TopTinTucDetailModelFromJson(
        Map<String, dynamic> json) =>
    TopTinTucDetailModel(
      id: json['id'] as String?,
      tieuDe: json['tieuDe'] as String?,
      noiDung: json['noiDung'] as String?,
      tacGia: json['tacGia'] as String?,
      nguonTin: json['nguonTin'] as String?,
    );

Map<String, dynamic> _$TopTinTucDetailModelToJson(
        TopTinTucDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tieuDe': instance.tieuDe,
      'noiDung': instance.noiDung,
      'tacGia': instance.tacGia,
      'nguonTin': instance.nguonTin,
    };
