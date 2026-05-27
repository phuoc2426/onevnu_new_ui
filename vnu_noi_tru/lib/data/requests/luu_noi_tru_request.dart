class LuuNoiTruRequest {
  LuuNoiTruRequest({
    required this.cmndCccd,
    required this.idDoiTuongUuTien,
    required this.trangThai,
    required this.idDotDangKy,
    required this.idTrungTamLuuTru,
    required this.idLoaiPhong,
    required this.filesDinhKem,
  });

  String cmndCccd;
  List<int> idDoiTuongUuTien;
  int trangThai;
  int idDotDangKy;
  int idTrungTamLuuTru;
  int idLoaiPhong;
  List<int> filesDinhKem;

  Map<String, dynamic> toJson() => {
        "CMND_CCCD": cmndCccd,
        "ID_DoiTuongUuTien": idDoiTuongUuTien,
        "TrangThai": trangThai,
        "ID_DotDangKy": idDotDangKy,
        "ID_TrungTamLuuTru": idTrungTamLuuTru,
        "ID_LoaiPhong": idLoaiPhong,
        "FilesDinhKem": filesDinhKem,
      };
}
