// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chuyen_nganh_dao_tao_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChuyenNganhDaoTaoModel _$ChuyenNganhDaoTaoModelFromJson(
        Map<String, dynamic> json) =>
    ChuyenNganhDaoTaoModel(
      id: json['id'] as String?,
      ma: json['ma'] as String?,
      ten: json['ten'] as String?,
      idNganhDaoTao: json['idNganhDaoTao'] as String?,
      guidDonVi: json['guidDonVi'] as String?,
    );

Map<String, dynamic> _$ChuyenNganhDaoTaoModelToJson(
        ChuyenNganhDaoTaoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ma': instance.ma,
      'ten': instance.ten,
      'idNganhDaoTao': instance.idNganhDaoTao,
      'guidDonVi': instance.guidDonVi,
    };
