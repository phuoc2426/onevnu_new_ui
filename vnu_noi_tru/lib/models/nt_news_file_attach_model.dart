class NtNewsFileAttachModel {
  NtNewsFileAttachModel({
    this.filename,
    this.fileUrl,
  });

  String? filename;
  String? fileUrl;

  factory NtNewsFileAttachModel.fromJson(Map<String, dynamic> json) =>
      NtNewsFileAttachModel(
        filename: json["filename"],
        fileUrl: json["fileUrl"],
      );

  Map<String, dynamic> toJson() => {
        "filename": filename,
        "fileUrl": fileUrl,
      };
}
