// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nguon_tuyen_sinh_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NguonTuyenSinhModel _$NguonTuyenSinhModelFromJson(Map<String, dynamic> json) =>
    NguonTuyenSinhModel(
      id: json['id'] as String?,
      ma: json['ma'],
      ten: json['ten'] as String?,
      guidDonVi: json['guidDonVi'] as String?,
    );

Map<String, dynamic> _$NguonTuyenSinhModelToJson(
        NguonTuyenSinhModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ma': instance.ma,
      'ten': instance.ten,
      'guidDonVi': instance.guidDonVi,
    };
