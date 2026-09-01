// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tao_hoi_dap_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaoHoiDapRequest _$TaoHoiDapRequestFromJson(Map<String, dynamic> json) =>
    TaoHoiDapRequest(
      guidChuDe: json['guidChuDe'] as String?,
      guidFileDinhKems: (json['guidFileDinhKems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      cauHoi: json['cauHoi'] as String?,
    );

Map<String, dynamic> _$TaoHoiDapRequestToJson(TaoHoiDapRequest instance) =>
    <String, dynamic>{
      'guidChuDe': instance.guidChuDe,
      'guidFileDinhKems': instance.guidFileDinhKems,
      'cauHoi': instance.cauHoi,
    };
