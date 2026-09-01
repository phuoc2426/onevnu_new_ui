// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hoi_dap_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HoiDapModel _$HoiDapModelFromJson(Map<String, dynamic> json) => HoiDapModel(
      guidChuDe: json['guidChuDe'] as String?,
      cauHoi: json['cauHoi'] as String?,
      guidFileDinhKems: (json['guidFileDinhKems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      guid: json['guid'] as String?,
      nguoiGui: json['nguoiGui'] as String?,
      maSinhVien: json['maSinhVien'] as String?,
      thoiGianGui: json['thoiGianGui'] == null
          ? null
          : DateTime.parse(json['thoiGianGui'] as String),
      tenFileDinhKem: json['tenFileDinhKem'],
      tenChuDe: json['tenChuDe'] as String?,
    );

Map<String, dynamic> _$HoiDapModelToJson(HoiDapModel instance) =>
    <String, dynamic>{
      'guidChuDe': instance.guidChuDe,
      'cauHoi': instance.cauHoi,
      'guidFileDinhKems': instance.guidFileDinhKems,
      'guid': instance.guid,
      'nguoiGui': instance.nguoiGui,
      'maSinhVien': instance.maSinhVien,
      'thoiGianGui': instance.thoiGianGui?.toIso8601String(),
      'tenFileDinhKem': instance.tenFileDinhKem,
      'tenChuDe': instance.tenChuDe,
    };
