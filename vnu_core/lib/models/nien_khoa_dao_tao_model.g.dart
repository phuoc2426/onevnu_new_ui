// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nien_khoa_dao_tao_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NienKhoaDaoTaoModel _$NienKhoaDaoTaoModelFromJson(Map<String, dynamic> json) =>
    NienKhoaDaoTaoModel(
      id: json['id'] as String?,
      ma: json['ma'] as String?,
      ten: json['ten'] as String?,
      idBacDaoTao: json['idBacDaoTao'] as String?,
      namBatDau: json['namBatDau'] as String?,
      namKetThuc: json['namKetThuc'] as String?,
      guidDonVi: json['guidDonVi'] as String?,
    );

Map<String, dynamic> _$NienKhoaDaoTaoModelToJson(
        NienKhoaDaoTaoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ma': instance.ma,
      'ten': instance.ten,
      'idBacDaoTao': instance.idBacDaoTao,
      'namBatDau': instance.namBatDau,
      'namKetThuc': instance.namKetThuc,
      'guidDonVi': instance.guidDonVi,
    };
