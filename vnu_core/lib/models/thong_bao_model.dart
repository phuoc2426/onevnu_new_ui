// To parse this JSON data, do
//
//     final thongBaoModel = thongBaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'thong_bao_model.g.dart';

ThongBaoModel thongBaoModelFromJson(String str) =>
    ThongBaoModel.fromJson(json.decode(str));

String thongBaoModelToJson(ThongBaoModel data) => json.encode(data.toJson());

@JsonSerializable()
class ThongBaoModel {
  @JsonKey(name: "tieuDe")
  String? tieuDe;
  @JsonKey(name: "noiDung")
  String? noiDung;
  @JsonKey(name: "isRead")
  bool? isRead;
  @JsonKey(name: "ngayGui")
  DateTime? ngayGui;
  @JsonKey(name: "tenNguoiGui")
  String? tenNguoiGui;
  @JsonKey(name: "guidAnhHienThi")
  String? guidAnhHienThi;
  @JsonKey(name: "loaiNotification")
  String? loaiNotification;
  @JsonKey(name: "guidItem")
  String? guidItem;

  ThongBaoModel({
    this.tieuDe,
    this.noiDung,
    this.isRead,
    this.ngayGui,
    this.tenNguoiGui,
    this.guidAnhHienThi,
    this.loaiNotification,
    this.guidItem,
  });

  ThongBaoModel copyWith({
    String? tieuDe,
    String? noiDung,
    bool? isRead,
    DateTime? ngayGui,
    String? tenNguoiGui,
    String? guidAnhHienThi,
    String? loaiNotification,
    String? guidItem,
  }) =>
      ThongBaoModel(
        tieuDe: tieuDe ?? this.tieuDe,
        noiDung: noiDung ?? this.noiDung,
        isRead: isRead ?? this.isRead,
        ngayGui: ngayGui ?? this.ngayGui,
        tenNguoiGui: tenNguoiGui ?? this.tenNguoiGui,
        guidAnhHienThi: guidAnhHienThi ?? this.guidAnhHienThi,
        loaiNotification: loaiNotification ?? this.loaiNotification,
        guidItem: guidItem ?? this.guidItem,
      );

  factory ThongBaoModel.fromJson(Map<String, dynamic> json) =>
      _$ThongBaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ThongBaoModelToJson(this);
}
