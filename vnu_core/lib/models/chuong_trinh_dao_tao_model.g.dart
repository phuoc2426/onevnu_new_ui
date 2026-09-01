// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chuong_trinh_dao_tao_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChuongTrinhDaoTaoModel _$ChuongTrinhDaoTaoModelFromJson(
        Map<String, dynamic> json) =>
    ChuongTrinhDaoTaoModel(
      id: json['id'] as String?,
      ma: json['ma'] as String?,
      ten: json['ten'] as String?,
      idHeDaoTao: json['idHeDaoTao'] as String?,
      idNganhDaoTao: json['idNganhDaoTao'] as String?,
      idNienKhoaDaoTao: json['idNienKhoaDaoTao'] as String?,
      idBacDaoTao: json['idBacDaoTao'] as String?,
      guidDonVi: json['guidDonVi'] as String?,
    );

Map<String, dynamic> _$ChuongTrinhDaoTaoModelToJson(
        ChuongTrinhDaoTaoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ma': instance.ma,
      'ten': instance.ten,
      'idHeDaoTao': instance.idHeDaoTao,
      'idNganhDaoTao': instance.idNganhDaoTao,
      'idNienKhoaDaoTao': instance.idNienKhoaDaoTao,
      'idBacDaoTao': instance.idBacDaoTao,
      'guidDonVi': instance.guidDonVi,
    };
