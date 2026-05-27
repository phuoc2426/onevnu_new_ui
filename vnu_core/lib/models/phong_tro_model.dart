// To parse this JSON data, do
//
//     final phongTroModel = phongTroModelFromJson(jsonString);
import 'package:intl/intl.dart';

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';

part 'phong_tro_model.g.dart';

PhongTroModel phongTroModelFromJson(String str) =>
    PhongTroModel.fromJson(json.decode(str));

String phongTroModelToJson(PhongTroModel data) => json.encode(data.toJson());

@JsonSerializable()
class PhongTroModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "tenChuTro")
  String? tenChuTro;
  @JsonKey(name: "soDienThoai")
  String? soDienThoai;
  @JsonKey(name: "guidKhuVucBanDo")
  String? guidKhuVucBanDo;
  @JsonKey(name: "tenKhuVucBanDo")
  String? tenKhuVucBanDo;
  @JsonKey(name: "diaChi")
  String? diaChi;
  @JsonKey(name: "ngayDang")
  DateTime? ngayDang;
  @JsonKey(name: "soLuongPhong")
  int? soLuongPhong;
  @JsonKey(name: "dienTichFrom")
  int? dienTichFrom;
  @JsonKey(name: "dienTichTo")
  int? dienTichTo;
  @JsonKey(name: "giaThueFrom")
  int? giaThueFrom;
  @JsonKey(name: "giaThueTo")
  int? giaThueTo;
  @JsonKey(name: "thietBiTrongPhong")
  String? thietBiTrongPhong;
  @JsonKey(name: "moTaChiTiet")
  String? moTaChiTiet;
  @JsonKey(name: "guidFileAnhNhaTros")
  List<String>? guidFileAnhNhaTros;

  PhongTroModel({
    this.guid,
    this.tenChuTro,
    this.soDienThoai,
    this.guidKhuVucBanDo,
    this.tenKhuVucBanDo,
    this.diaChi,
    this.ngayDang,
    this.soLuongPhong,
    this.dienTichFrom,
    this.dienTichTo,
    this.giaThueFrom,
    this.giaThueTo,
    this.thietBiTrongPhong,
    this.moTaChiTiet,
    this.guidFileAnhNhaTros,
  });

  PhongTroModel copyWith({
    String? guid,
    String? tenChuTro,
    String? soDienThoai,
    String? guidKhuVucBanDo,
    String? tenKhuVucBanDo,
    String? diaChi,
    DateTime? ngayDang,
    int? soLuongPhong,
    int? dienTichFrom,
    int? dienTichTo,
    int? giaThueFrom,
    int? giaThueTo,
    String? thietBiTrongPhong,
    String? moTaChiTiet,
    List<String>? guidFileAnhNhaTros,
  }) =>
      PhongTroModel(
        guid: guid ?? this.guid,
        tenChuTro: tenChuTro ?? this.tenChuTro,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        guidKhuVucBanDo: guidKhuVucBanDo ?? this.guidKhuVucBanDo,
        tenKhuVucBanDo: tenKhuVucBanDo ?? this.tenKhuVucBanDo,
        diaChi: diaChi ?? this.diaChi,
        ngayDang: ngayDang ?? this.ngayDang,
        soLuongPhong: soLuongPhong ?? this.soLuongPhong,
        dienTichFrom: dienTichFrom ?? this.dienTichFrom,
        dienTichTo: dienTichTo ?? this.dienTichTo,
        giaThueFrom: giaThueFrom ?? this.giaThueFrom,
        giaThueTo: giaThueTo ?? this.giaThueTo,
        thietBiTrongPhong: thietBiTrongPhong ?? this.thietBiTrongPhong,
        moTaChiTiet: moTaChiTiet ?? this.moTaChiTiet,
        guidFileAnhNhaTros: guidFileAnhNhaTros ?? this.guidFileAnhNhaTros,
      );

  factory PhongTroModel.fromJson(Map<String, dynamic> json) =>
      _$PhongTroModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhongTroModelToJson(this);

  String giaThueFromString() {
    int flutterBalance = giaThueFrom ?? 0;
    final oCcy = NumberFormat("#,##0", "vi_VN");
    String formatted = oCcy.format(flutterBalance);
    //print(formatted); // something like 94,510.60
    return formatted;
  }

  String giaThueToString() {
    int flutterBalance = giaThueTo ?? 0;
    final oCcy = NumberFormat("#,##0", "vi_VN");
    String formatted = oCcy.format(flutterBalance);
    //print(formatted); // something like 94,510.60
    return formatted;
  }

  String ngayDangString() {
    if (ngayDang == null) {
      return '';
    }
    return DateTimeUtils.stringFromDateTime(
        ngayDang, DateTimeConst.DATE_FORMAT);
  }
}
