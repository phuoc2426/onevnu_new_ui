// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dia_diem_ban_do_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaDiemBanDoModel _$DiaDiemBanDoModelFromJson(Map<String, dynamic> json) =>
    DiaDiemBanDoModel(
      guid: json['guid'] as String?,
      tenKhuVucBanDo: json['tenKhuVucBanDo'] as String?,
      tenLoaiDiaDiemBanDo: json['tenLoaiDiaDiemBanDo'] as String?,
      tenDiaDiem: json['tenDiaDiem'] as String?,
      kinhDoViDo: json['kinhDoViDo'] as String?,
      guidKhuVucBanDo: json['guidKhuVucBanDo'] as String?,
      guidLoaiDiaDiemBanDo: json['guidLoaiDiaDiemBanDo'] as String?,
    );

Map<String, dynamic> _$DiaDiemBanDoModelToJson(DiaDiemBanDoModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'tenKhuVucBanDo': instance.tenKhuVucBanDo,
      'tenLoaiDiaDiemBanDo': instance.tenLoaiDiaDiemBanDo,
      'tenDiaDiem': instance.tenDiaDiem,
      'kinhDoViDo': instance.kinhDoViDo,
      'guidKhuVucBanDo': instance.guidKhuVucBanDo,
      'guidLoaiDiaDiemBanDo': instance.guidLoaiDiaDiemBanDo,
    };
