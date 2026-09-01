// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phong_tro_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhongTroModel _$PhongTroModelFromJson(Map<String, dynamic> json) =>
    PhongTroModel(
      guid: json['guid'] as String?,
      tenChuTro: json['tenChuTro'] as String?,
      soDienThoai: json['soDienThoai'] as String?,
      guidKhuVucBanDo: json['guidKhuVucBanDo'] as String?,
      tenKhuVucBanDo: json['tenKhuVucBanDo'] as String?,
      diaChi: json['diaChi'] as String?,
      ngayDang: json['ngayDang'] == null
          ? null
          : DateTime.parse(json['ngayDang'] as String),
      soLuongPhong: (json['soLuongPhong'] as num?)?.toInt(),
      dienTichFrom: (json['dienTichFrom'] as num?)?.toInt(),
      dienTichTo: (json['dienTichTo'] as num?)?.toInt(),
      giaThueFrom: (json['giaThueFrom'] as num?)?.toInt(),
      giaThueTo: (json['giaThueTo'] as num?)?.toInt(),
      thietBiTrongPhong: json['thietBiTrongPhong'] as String?,
      moTaChiTiet: json['moTaChiTiet'] as String?,
      guidFileAnhNhaTros: (json['guidFileAnhNhaTros'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PhongTroModelToJson(PhongTroModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'tenChuTro': instance.tenChuTro,
      'soDienThoai': instance.soDienThoai,
      'guidKhuVucBanDo': instance.guidKhuVucBanDo,
      'tenKhuVucBanDo': instance.tenKhuVucBanDo,
      'diaChi': instance.diaChi,
      'ngayDang': instance.ngayDang?.toIso8601String(),
      'soLuongPhong': instance.soLuongPhong,
      'dienTichFrom': instance.dienTichFrom,
      'dienTichTo': instance.dienTichTo,
      'giaThueFrom': instance.giaThueFrom,
      'giaThueTo': instance.giaThueTo,
      'thietBiTrongPhong': instance.thietBiTrongPhong,
      'moTaChiTiet': instance.moTaChiTiet,
      'guidFileAnhNhaTros': instance.guidFileAnhNhaTros,
    };
