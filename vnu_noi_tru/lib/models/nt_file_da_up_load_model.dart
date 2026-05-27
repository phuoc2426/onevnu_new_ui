// To parse this JSON data, do
//
//     final fileDaUploadModel = fileDaUploadModelFromJson(jsonString);

import 'dart:convert';

NtFileDaUploadModel fileDaUploadModelFromJson(String str) =>
    NtFileDaUploadModel.fromJson(json.decode(str));

String fileDaUploadModelToJson(NtFileDaUploadModel data) =>
    json.encode(data.toJson());

class NtFileDaUploadModel {
  NtFileDaUploadModel({
    this.id,
    this.duongDanFile,
  });

  int? id;
  String? duongDanFile;

  factory NtFileDaUploadModel.fromJson(Map<String, dynamic> json) =>
      NtFileDaUploadModel(
        id: json["Id"],
        duongDanFile: json["DuongDanFile"],
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "DuongDanFile": duongDanFile,
      };
}
