import 'package:vnu_noi_tru/models/model.dart';

class PhieuDangKyNoiTruModel {
  PhieuDangKyNoiTruModel({
    this.id,
    this.danhSachDoiTuongUuTien,
    this.danhSachFileDaUpLoad,
    this.dotDangKy,
    this.trungTamLuuTru,
    this.loaiPhong,
  });

  int? id;
  List<DanhSachDoiTuongUuTien>? danhSachDoiTuongUuTien;
  List<NtFileDaUploadModel>? danhSachFileDaUpLoad;
  DanhSachDotDangKyLuuTru? dotDangKy;
  DanhSachTrungTamLuuTru? trungTamLuuTru;
  DanhSachLoaiPhong? loaiPhong;

  factory PhieuDangKyNoiTruModel.fromJson(Map<String, dynamic> json) =>
      PhieuDangKyNoiTruModel(
        id: json["Id"],
        danhSachDoiTuongUuTien: List<DanhSachDoiTuongUuTien>.from(
            (json["DanhSachDoiTuongUuTien"] ?? [])
                .map((x) => DanhSachDoiTuongUuTien.fromJson(x))),
        danhSachFileDaUpLoad: List<NtFileDaUploadModel>.from(
            (json["DanhSachFileDaUpLoad"] ?? [])
                .map((x) => NtFileDaUploadModel.fromJson(x))),
        dotDangKy: DanhSachDotDangKyLuuTru.fromJson(json["DotDangKy"]),
        trungTamLuuTru: DanhSachTrungTamLuuTru.fromJson(json["TrungTamLuuTru"]),
        loaiPhong: DanhSachLoaiPhong.fromJson(json["LoaiPhong"]),
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "DanhSachDoiTuongUuTien":
            List<int>.from((danhSachDoiTuongUuTien ?? []).map((x) => x)),
        "DanhSachFileDaUpLoad":
            List<int>.from((danhSachFileDaUpLoad ?? []).map((x) => x)),
        "DotDangKy": dotDangKy?.toJson(),
        "TrungTamLuuTru": trungTamLuuTru?.toJson(),
        "LoaiPhong": loaiPhong?.toJson(),
      };
}

class ListPhieuDangKyNoiTruResponse {
  final List<PhieuDangKyNoiTruModel>? phieuDangKy;

  const ListPhieuDangKyNoiTruResponse({this.phieuDangKy});

  factory ListPhieuDangKyNoiTruResponse.fromJson(List<dynamic> json) {
    List<PhieuDangKyNoiTruModel> listObj = [];
    for (var element in json) {
      if (element is Map<String, dynamic>) {
        listObj.add(PhieuDangKyNoiTruModel.fromJson(element));
      }
    }
    return ListPhieuDangKyNoiTruResponse(phieuDangKy: listObj);
  }
}
