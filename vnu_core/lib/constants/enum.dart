// ignore_for_file: constant_identifier_names

enum DownloadMode { SaveDocument, PreviewTemp }

extension DownloadModeExtension on DownloadMode {
  String get description {
    switch (this) {
      case DownloadMode.SaveDocument:
        return 'Lưu tệp tải về vào thưc mục Document/iOffice V6 của ứng dụng/điện thoại';
      case DownloadMode.PreviewTemp:
        return 'Lưu tệp tải về vào thưc mục tạm trên điện thoại';
      default:
        return '';
    }
  }
}

enum NotifyStatus { unRead, all }

enum HomeService {
  CamNang,
  BanDoSo,
  DangKyNoiTru,
  MucHoiDap,
  ThuTucMotCua,
  TimPhongTro,
  XemThoiKhoaBieu,
  XemLichThi,
  DiemMonHoc,
  HuongDanSuDung,
  PhanAnhHienTruong,
  TheSinhVien
}

extension HomeServiceExtension on HomeService {
  String get ordinal {
    switch (this) {
      case HomeService.CamNang:
        return 'CamNang';
      case HomeService.BanDoSo:
        return 'BanDoSo';
      case HomeService.DangKyNoiTru:
        return 'DangKyKiTucXa';
      case HomeService.MucHoiDap:
        return 'MucHoiDap';
      case HomeService.ThuTucMotCua:
        return 'ThuTucMotCua';
      case HomeService.TimPhongTro:
        return 'TimPhongTro';
      case HomeService.XemThoiKhoaBieu:
        return 'XemThoiKhoaBieu';
      case HomeService.XemLichThi:
        return 'XemLichThi';
      case HomeService.DiemMonHoc:
        return 'DiemMonHoc';
      case HomeService.HuongDanSuDung:
        return 'HuongDanSuDung';
      case HomeService.PhanAnhHienTruong:
        return 'PhanAnhHienTruong';
      case HomeService.TheSinhVien:
        return 'TheSinhVien';
    }
  }

  String get title {
    switch (this) {
      case HomeService.CamNang:
        return 'Cẩm nang';
      case HomeService.BanDoSo:
        return 'Bản đồ số';
      case HomeService.DangKyNoiTru:
        return 'Đăng ký nội trú';
      case HomeService.MucHoiDap:
        return 'Mục hỏi đáp';
      case HomeService.ThuTucMotCua:
        return 'Thủ tục một cửa';
      case HomeService.TimPhongTro:
        return 'Tìm phòng trọ';
      case HomeService.XemThoiKhoaBieu:
        return 'Lịch học & Lịch thi';
      case HomeService.XemLichThi:
        return 'Lịch thi';
      case HomeService.DiemMonHoc:
        return 'Điểm môn học';
      case HomeService.HuongDanSuDung:
        return 'Hướng dẫn sử dụng';
      case HomeService.PhanAnhHienTruong:
        return 'Phản ánh hiện trường';
      case HomeService.TheSinhVien:
        return 'Thẻ sinh viên';
    }
  }

  String get icon {
    switch (this) {
      case HomeService.CamNang:
        return 'ic_cam_nang.svg';
      case HomeService.BanDoSo:
        return 'ic_ban_do_so.svg';
      case HomeService.DangKyNoiTru:
        return 'ic_noi_tru.svg';
      case HomeService.MucHoiDap:
        return 'ic_hoi_dap.svg';
      case HomeService.ThuTucMotCua:
        return 'ic_mot_cua.svg';
      case HomeService.TimPhongTro:
        return 'ic_phong_tro.svg';
      case HomeService.XemThoiKhoaBieu:
        return 'ic_thoi_khoa_bieu.svg';
      case HomeService.XemLichThi:
        return 'ic_lich_thi.svg';
      case HomeService.DiemMonHoc:
        return 'ic_diem_mon_hoc.svg';
      case HomeService.HuongDanSuDung:
        return 'ic_hdsd.svg';
      case HomeService.PhanAnhHienTruong:
        return 'ic_paht.svg';
      case HomeService.TheSinhVien:
        return 'ic_the_sinh_vien.svg';
    }
  }
}

enum LoaiThongBao {
  CamNang,
  TinTuc,
  Cmsvnu_TinTuc,
  Cmsvnu_ThongBao,
  TinHeThong,
  ChuDeCauHoi,
  CauHoi,
  TraLoiCauHoi,
  PhongTro,
  HuongDanSuDung,
  ThuTucHanhChinh,
  TraLoiPhanAnh
}

// extension LoaiThongBaoExtension on LoaiThongBao {
//   String get title {
//     switch (this) {
//       case LoaiThongBao.CamNang:
//         return 'CamNang';
//       case LoaiThongBao.TinTuc:
//         return 'TinTuc';
//       case LoaiThongBao.Cmsvnu_TinTuc:
//         return 'Cmsvnu_TinTuc';
//       case LoaiThongBao.Cmsvnu_ThongBao:
//         return 'Cmsvnu_ThongBao';
//       case LoaiThongBao.TinHeThong:
//         return 'TinHeThong';
//       case LoaiThongBao.ChuDeCauHoi:
//         return 'ChuDeCauHoi';
//       case LoaiThongBao.CauHoi:
//         return 'CauHoi';
//       case LoaiThongBao.TraLoiCauHoi:
//         return 'TraLoiCauHoi';
//       case LoaiThongBao.PhongTro:
//         return 'PhongTro';
//       case LoaiThongBao.HuongDanSuDung:
//         return 'HuongDanSuDung';
//       case LoaiThongBao.ThuTucHanhChinh:
//         return 'ThuTucHanhChinh';
//     }
//   }
// }

enum UploadFileState { success, none, failed, uploading }
