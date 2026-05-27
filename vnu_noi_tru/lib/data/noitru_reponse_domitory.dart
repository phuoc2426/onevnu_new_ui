import 'dart:convert';
import 'dart:core';
import 'package:vnu_core/models/login_reponse_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vnu_core/models/token_model.dart';

import '../models/model.dart';
part 'noitru_reponse_domitory.g.dart';

@JsonSerializable()
class NoitruResponseDomitory<T> {
  final int? resultCode;
  final String? resultMessage;
  @_Converter()
  final T data;

  NoitruResponseDomitory(
      {this.resultCode, this.resultMessage, required this.data});

  factory NoitruResponseDomitory.fromJson(Map<String, dynamic> json) =>
      _$NoitruResponseDomitoryFromJson(json);
  Map<String, dynamic> toJson() => _$NoitruResponseDomitoryToJson(this);
}

class _Converter<T> implements JsonConverter<T, Object> {
  const _Converter();

  @override
  fromJson(Object? json) {
    if (T == NtDanhSachQtxlModel) {
      return NtDanhSachQtxlModel.fromJson(json as Map<String, dynamic>) as T;
    }
    if (T == NtDanhSachTrungTamLuuTruModel) {
      return NtDanhSachTrungTamLuuTruModel.fromJson(
          json as Map<String, dynamic>) as T;
    }
    if (T == NtDanhSachDoiTuongUuTienModel) {
      return NtDanhSachDoiTuongUuTienModel.fromJson(
          json as Map<String, dynamic>) as T;
    }
    if (T == NtDanhSachDotDangKyLuuTruModel) {
      return NtDanhSachDotDangKyLuuTruModel.fromJson(
          json as Map<String, dynamic>) as T;
    }
    if (T == NtDanhSachPhongModel) {
      return NtDanhSachPhongModel.fromJson(json as Map<String, dynamic>) as T;
    }

    if (T == ListPhieuDangKyNoiTruResponse) {
      return ListPhieuDangKyNoiTruResponse.fromJson(json as List<dynamic>) as T;
    }
    if (T == NtUrlPresignedModel) {
      return NtUrlPresignedModel.fromJson(json as Map<String, dynamic>) as T;
    }

    if (T == bool) {
      return json as T;
    }
    if (T == dynamic) {
      return json as dynamic;
    }
    if (T == String) {
      return json as T;
    }
    return {} as T;
  }

  @override
  Object toJson(T? object) {
    return json.encode(object);
  }
}
