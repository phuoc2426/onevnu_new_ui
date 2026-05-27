class NtThongBaoSoLuongChuaDocModel {
  NtThongBaoSoLuongChuaDocModel({
    this.soLuongChuaDoc,
  });

  int? soLuongChuaDoc;

  factory NtThongBaoSoLuongChuaDocModel.fromJson(Map<String, dynamic> json) =>
      NtThongBaoSoLuongChuaDocModel(
        soLuongChuaDoc: json["SoLuongChuaDoc"],
      );

  Map<String, dynamic> toJson() => {
        "SoLuongChuaDoc": soLuongChuaDoc,
      };
}
