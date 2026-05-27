import 'package:vnu_core/models/model.dart';

class ThongTinSinhVienModel {
  ThongTinSinhVienModel({
    this.id,
    this.hoTen,
    this.ngaySinh,
    this.gioiTinh,
    this.danToc,
    this.tonGiao,
    this.quocTich,
    this.maSinhVien,
    this.loaiGiayTo,
    this.cmndCccd,
    this.ngayCap,
    this.noiCap,
    this.ngayVaoDoan,
    this.diaChiThuongTru,
    this.thongTinNhapHoc,
    this.thongTinBo,
    this.thongTinMe,
    this.thongTinLienHe,
  });

  int? id;
  String? hoTen;
  String? ngaySinh;
  String? gioiTinh;
  String? danToc;
  String? tonGiao;
  String? quocTich;
  String? maSinhVien;
  String? loaiGiayTo;
  String? cmndCccd;
  String? ngayCap;
  String? noiCap;
  String? ngayVaoDoan;
  ThongTinDiaChiThuongTruModel? diaChiThuongTru;
  ThongTinNhapHocModel? thongTinNhapHoc;
  ThongTinPhuHuynhModel? thongTinBo;
  ThongTinPhuHuynhModel? thongTinMe;
  ThongTinLienHeModel? thongTinLienHe;

  factory ThongTinSinhVienModel.fromJson(Map<String, dynamic> json) =>
      ThongTinSinhVienModel(
        id: json["Id"],
        hoTen: json["HoTen"],
        ngaySinh: json["NgaySinh"],
        gioiTinh: json["GioiTinh"],
        danToc: json["DanToc"],
        tonGiao: json["TonGiao"],
        quocTich: json["QuocTich"],
        maSinhVien: json["MaSinhVien"],
        loaiGiayTo: json["LoaiGiayTo"],
        cmndCccd: json["CMND_CCCD"],
        ngayCap: json["NgayCap"],
        noiCap: json["NoiCap"],
        ngayVaoDoan: json["NgayVaoDoan"],
        diaChiThuongTru:
            ThongTinDiaChiThuongTruModel.fromJson(json["DiaChiThuongTru"]),
        thongTinNhapHoc: ThongTinNhapHocModel.fromJson(json["ThongTinNhapHoc"]),
        thongTinBo: ThongTinPhuHuynhModel.fromJson(json["ThongTinBo"]),
        thongTinMe: ThongTinPhuHuynhModel.fromJson(json["ThongTinMe"]),
        thongTinLienHe: ThongTinLienHeModel.fromJson(json["ThongTinLienHe"]),
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "HoTen": hoTen,
        "NgaySinh": ngaySinh,
        "GioiTinh": gioiTinh,
        "DanToc": danToc,
        "TonGiao": tonGiao,
        "QuocTich": quocTich,
        "MaSinhVien": maSinhVien,
        "LoaiGiayTo": loaiGiayTo,
        "CMND_CCCD": cmndCccd,
        "NgayCap": ngayCap,
        "NoiCap": noiCap,
        "NgayVaoDoan": ngayVaoDoan,
        "DiaChiThuongTru": diaChiThuongTru?.toJson(),
        "ThongTinNhapHoc": thongTinNhapHoc?.toJson(),
        "ThongTinBo": thongTinBo?.toJson(),
        "ThongTinMe": thongTinMe?.toJson(),
        "ThongTinLienHe": thongTinLienHe?.toJson(),
      };
}
