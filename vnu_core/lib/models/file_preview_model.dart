// To parse this JSON data, do
//
//     final filePreviewModel = filePreviewModelFromJson(jsonString);

import 'dart:convert';

FilePreviewModel filePreviewModelFromJson(String str) =>
    FilePreviewModel.fromJson(json.decode(str));

String filePreviewModelToJson(FilePreviewModel data) =>
    json.encode(data.toJson());

class FilePreviewModel {
  FilePreviewModel({
    this.fileUrl,
  });

  String? fileUrl;

  factory FilePreviewModel.fromJson(Map<String, dynamic> json) =>
      FilePreviewModel(
        fileUrl: json["FileURL"],
      );

  Map<String, dynamic> toJson() => {
        "FileURL": fileUrl,
      };
}
