// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thu_tuc_mot_cua_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThuTucMotCuaModel _$ThuTucMotCuaModelFromJson(Map<String, dynamic> json) =>
    ThuTucMotCuaModel(
      guidLinhVuc: json['guidLinhVuc'] as String?,
      tenThuTuc: json['tenThuTuc'] as String?,
      htmlNoiDung: json['htmlNoiDung'] as String?,
      tenLinhVuc: json['tenLinhVuc'] as String?,
      guid: json['guid'] as String?,
      thanhPhanHoSo: (json['thanhPhanHoSo'] as List<dynamic>?)
          ?.map((e) => ThanhPhanHoSo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ThuTucMotCuaModelToJson(ThuTucMotCuaModel instance) =>
    <String, dynamic>{
      'guidLinhVuc': instance.guidLinhVuc,
      'tenThuTuc': instance.tenThuTuc,
      'htmlNoiDung': instance.htmlNoiDung,
      'tenLinhVuc': instance.tenLinhVuc,
      'guid': instance.guid,
      'thanhPhanHoSo': instance.thanhPhanHoSo,
    };

ThanhPhanHoSo _$ThanhPhanHoSoFromJson(Map<String, dynamic> json) =>
    ThanhPhanHoSo(
      tenHoSo: json['tenHoSo'] as String?,
      tenFileDinhKem: json['tenFileDinhKem'] as String?,
      guidFileDinhKems: (json['guidFileDinhKems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ThanhPhanHoSoToJson(ThanhPhanHoSo instance) =>
    <String, dynamic>{
      'tenHoSo': instance.tenHoSo,
      'tenFileDinhKem': instance.tenFileDinhKem,
      'guidFileDinhKems': instance.guidFileDinhKems,
    };
