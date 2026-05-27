// To parse this JSON data, do
//
//     final ntItemMenuModel = ntItemMenuModelFromJson(jsonString);

import 'dart:convert';

NtItemMenuModel ntItemMenuModelFromJson(String str) =>
    NtItemMenuModel.fromJson(json.decode(str));

String ntItemMenuModelToJson(NtItemMenuModel data) =>
    json.encode(data.toJson());

class NtItemMenuModel {
  NtItemMenuModel({
    this.id,
    this.tenMenu,
    this.screenName,
  });

  int? id;
  String? tenMenu;
  String? screenName;

  factory NtItemMenuModel.fromJson(Map<String, dynamic> json) =>
      NtItemMenuModel(
        id: json["ID"],
        tenMenu: json["TenMenu"],
        screenName: json["ScreenName"],
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "TenMenu": tenMenu,
        "ScreenName": screenName,
      };
}
