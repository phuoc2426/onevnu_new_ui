// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thong_bao_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThongBaoModel _$ThongBaoModelFromJson(Map<String, dynamic> json) =>
    ThongBaoModel(
      tieuDe: json['tieuDe'] as String?,
      noiDung: json['noiDung'] as String?,
      isRead: json['isRead'] as bool?,
      ngayGui: json['ngayGui'] == null
          ? null
          : DateTime.parse(json['ngayGui'] as String),
      tenNguoiGui: json['tenNguoiGui'] as String?,
      guidAnhHienThi: json['guidAnhHienThi'] as String?,
      loaiNotification: json['loaiNotification'] as String?,
      guidItem: json['guidItem'] as String?,
    );

Map<String, dynamic> _$ThongBaoModelToJson(ThongBaoModel instance) =>
    <String, dynamic>{
      'tieuDe': instance.tieuDe,
      'noiDung': instance.noiDung,
      'isRead': instance.isRead,
      'ngayGui': instance.ngayGui?.toIso8601String(),
      'tenNguoiGui': instance.tenNguoiGui,
      'guidAnhHienThi': instance.guidAnhHienThi,
      'loaiNotification': instance.loaiNotification,
      'guidItem': instance.guidItem,
    };
