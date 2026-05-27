import 'dart:convert';
import 'dart:core';
import 'package:vnu_core/models/login_reponse_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vnu_noi_tru/models/nt_danh_sach_menu_model.dart';

import '../models/model.dart';
part 'noitru_response.g.dart';

@JsonSerializable()
class NoiTruResponse<T> {
  final String? resultCode;
  final String? resultMessage;
  @_Converter()
  final T data;

  NoiTruResponse({this.resultCode, this.resultMessage, required this.data});

  factory NoiTruResponse.fromJson(Map<String, dynamic> json) =>
      _$NoiTruResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NoiTruResponseToJson(this);
}

class _Converter<T> implements JsonConverter<T, Object> {
  const _Converter();

  @override
  fromJson(Object? json) {
    if (T == NtDanhSachTinTucModel) {
      return NtDanhSachTinTucModel.fromJson(json as Map<String, dynamic>) as T;
    }
    if (T == NtThongBaoSoLuongChuaDocModel) {
      return NtThongBaoSoLuongChuaDocModel.fromJson(
          json as Map<String, dynamic>) as T;
    }
    if (T == NtDanhSachThongBaoModel) {
      return NtDanhSachThongBaoModel.fromJson(json as Map<String, dynamic>)
          as T;
    }
    if (T == NtDanhSachMenuModel) {
      return NtDanhSachMenuModel.fromJson(json as Map<String, dynamic>) as T;
    }
    if (T == NtTinTucModel) {
      return NtTinTucModel.fromJson(json as Map<String, dynamic>) as T;
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
