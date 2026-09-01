// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'don_vi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonViModel _$DonViModelFromJson(Map<String, dynamic> json) => DonViModel(
      guid: json['guid'] as String?,
      tenDonVi: json['tenDonVi'] as String?,
      guidDonViCha: json['guidDonViCha'] as String?,
      capDonVi: (json['capDonVi'] as num?)?.toInt(),
      thuTu: (json['thuTu'] as num?)?.toInt(),
      idHeThongDaoTao: (json['idHeThongDaoTao'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DonViModelToJson(DonViModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'tenDonVi': instance.tenDonVi,
      'guidDonViCha': instance.guidDonViCha,
      'capDonVi': instance.capDonVi,
      'thuTu': instance.thuTu,
      'idHeThongDaoTao': instance.idHeThongDaoTao,
    };
