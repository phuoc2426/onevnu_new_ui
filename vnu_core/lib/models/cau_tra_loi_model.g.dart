// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cau_tra_loi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CauTraLoiModel _$CauTraLoiModelFromJson(Map<String, dynamic> json) =>
    CauTraLoiModel(
      guid: json['guid'] as String?,
      cauHoi: json['cauHoi'] as String?,
      guidChuDe: json['guidChuDe'] as String?,
      tenChuDe: json['tenChuDe'] as String?,
      tenFileDinhKem: json['tenFileDinhKem'] as String?,
      guidFileDinhKems: (json['guidFileDinhKems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      thoiGianGui: json['thoiGianGui'] == null
          ? null
          : DateTime.parse(json['thoiGianGui'] as String),
      tenNguoiTraLoi: json['tenNguoiTraLoi'] as String?,
      thoiGianTraLoi: json['thoiGianTraLoi'] == null
          ? null
          : DateTime.parse(json['thoiGianTraLoi'] as String),
      tenFileDinhKemTraLoi: json['tenFileDinhKemTraLoi'] as String?,
      guidFileDinhKemsTraLoi: (json['guidFileDinhKemsTraLoi'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      traLoi: json['traLoi'] as String?,
    );

Map<String, dynamic> _$CauTraLoiModelToJson(CauTraLoiModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'cauHoi': instance.cauHoi,
      'guidChuDe': instance.guidChuDe,
      'tenChuDe': instance.tenChuDe,
      'tenFileDinhKem': instance.tenFileDinhKem,
      'guidFileDinhKems': instance.guidFileDinhKems,
      'thoiGianGui': instance.thoiGianGui?.toIso8601String(),
      'tenNguoiTraLoi': instance.tenNguoiTraLoi,
      'thoiGianTraLoi': instance.thoiGianTraLoi?.toIso8601String(),
      'tenFileDinhKemTraLoi': instance.tenFileDinhKemTraLoi,
      'guidFileDinhKemsTraLoi': instance.guidFileDinhKemsTraLoi,
      'traLoi': instance.traLoi,
    };
