import 'model.dart';

class NtTinTucModel {
  NtTinTucModel({
    this.tinnTucModelId,
    this.tieuDe,
    this.noiDung,
    this.anhDaiDien,
    this.filesDinhKem,
    this.thoiGianXuatBan,
  });

  int? tinnTucModelId;
  String? tieuDe;
  String? noiDung;
  String? anhDaiDien;
  List<NtNewsFileAttachModel>? filesDinhKem;
  String? thoiGianXuatBan;

  factory NtTinTucModel.fromJson(Map<String, dynamic> json) => NtTinTucModel(
        tinnTucModelId: json["ID"],
        tieuDe: json["TieuDe"],
        noiDung: json["NoiDung"],
        anhDaiDien: json["AnhDaiDien"],
        filesDinhKem: List<NtNewsFileAttachModel>.from(
            json["FilesDinhKem"].map((x) => NtNewsFileAttachModel.fromJson(x))),
        thoiGianXuatBan: json["ThoiGianXuatBan"],
      );

  Map<String, dynamic> toJson() => {
        "ID": tinnTucModelId,
        "TieuDe": tieuDe,
        "NoiDung": noiDung,
        "AnhDaiDien": anhDaiDien,
        "FilesDinhKem":
            List<dynamic>.from((filesDinhKem ?? []).map((x) => x.toJson())),
        "ThoiGianXuatBan": thoiGianXuatBan,
      };
}
