// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nganh_dao_tao_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NganhDaoTaoModel _$NganhDaoTaoModelFromJson(Map<String, dynamic> json) =>
    NganhDaoTaoModel(
      id: json['id'] as String?,
      ma: json['ma'] as String?,
      ten: json['ten'] as String?,
      idBacDaoTao: json['idBacDaoTao'] as String?,
      guidDonVi: json['guidDonVi'] as String?,
    );

Map<String, dynamic> _$NganhDaoTaoModelToJson(NganhDaoTaoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ma': instance.ma,
      'ten': instance.ten,
      'idBacDaoTao': instance.idBacDaoTao,
      'guidDonVi': instance.guidDonVi,
    };
