// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tong_ket_den_hien_tai_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TongKetDenHienTaiModel _$TongKetDenHienTaiModelFromJson(
        Map<String, dynamic> json) =>
    TongKetDenHienTaiModel(
      soKyDaHoc: (json['soKyDaHoc'] as num?)?.toInt(),
      diemTrungBinhHe4TichLuy: json['diemTrungBinhHe4TichLuy'] as String?,
      tongSoTinChiTichLuy: json['tongSoTinChiTichLuy'] as String?,
    );

Map<String, dynamic> _$TongKetDenHienTaiModelToJson(
        TongKetDenHienTaiModel instance) =>
    <String, dynamic>{
      'soKyDaHoc': instance.soKyDaHoc,
      'diemTrungBinhHe4TichLuy': instance.diemTrungBinhHe4TichLuy,
      'tongSoTinChiTichLuy': instance.tongSoTinChiTichLuy,
    };
