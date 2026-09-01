// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quan_huyen_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuanHuyenModel _$QuanHuyenModelFromJson(Map<String, dynamic> json) =>
    QuanHuyenModel(
      id: json['id'] as String?,
      ten: json['ten'] as String?,
      idTinhThanhPho: json['idTinhThanhPho'] as String?,
      guidDonVi: json['guidDonVi'] as String?,
    );

Map<String, dynamic> _$QuanHuyenModelToJson(QuanHuyenModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ten': instance.ten,
      'idTinhThanhPho': instance.idTinhThanhPho,
      'guidDonVi': instance.guidDonVi,
    };
