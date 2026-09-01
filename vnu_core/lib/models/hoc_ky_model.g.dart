// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hoc_ky_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HocKyModel _$HocKyModelFromJson(Map<String, dynamic> json) => HocKyModel(
      id: json['id'] as String?,
      ten: json['ten'] as String?,
      nam: json['nam'] as String?,
      maHocKy: json['maHocKy'] as String?,
      ngayBatDau: json['ngayBatDau'] as String?,
      ngayKetThuc: json['ngayKetThuc'] as String?,
      preTerm: json['preTerm'] as String?,
      loaiHocKy: json['loaiHocKy'] as String?,
    );

Map<String, dynamic> _$HocKyModelToJson(HocKyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ten': instance.ten,
      'nam': instance.nam,
      'maHocKy': instance.maHocKy,
      'ngayBatDau': instance.ngayBatDau,
      'ngayKetThuc': instance.ngayKetThuc,
      'preTerm': instance.preTerm,
      'loaiHocKy': instance.loaiHocKy,
    };
