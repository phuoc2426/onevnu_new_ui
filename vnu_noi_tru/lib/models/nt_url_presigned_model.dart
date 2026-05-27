// To parse this JSON data, do
//
//     final ntUrlPresignedModel = ntUrlPresignedModelFromJson(jsonString);

import 'dart:convert';

NtUrlPresignedModel ntUrlPresignedModelFromJson(String str) =>
    NtUrlPresignedModel.fromJson(json.decode(str));

String ntUrlPresignedModelToJson(NtUrlPresignedModel data) =>
    json.encode(data.toJson());

class NtUrlPresignedModel {
  NtUrlPresignedModel({
    this.fileId,
    this.uploadUrl,
  });

  int? fileId;
  String? uploadUrl;

  factory NtUrlPresignedModel.fromJson(Map<String, dynamic> json) =>
      NtUrlPresignedModel(
        fileId: json["FileId"],
        uploadUrl: json["UploadUrl"],
      );

  Map<String, dynamic> toJson() => {
        "FileId": fileId,
        "UploadUrl": uploadUrl,
      };
}
