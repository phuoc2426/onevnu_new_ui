part of 'nt_register_cubit.dart';

@immutable
abstract class NtRegisterState {}

class NtRegisterInitial extends NtRegisterState {}

class NtRegisterShowHub extends NtRegisterState {}

class NtRegisterLoading extends NtRegisterState {}

class NtRegisterDismissHub extends NtRegisterState {}

class NtRegisterLoadedError extends NtRegisterState {
  String message;
  NtRegisterLoadedError(this.message);
}

class NtRegisterUpLoadedError extends NtRegisterState {
  String message;
  NtRegisterUpLoadedError(this.message);
}

class NtRegisterUpLoadedSuccess extends NtRegisterState {
  NtRegisterUpLoadedSuccess();
}

class NtRegisterLoadedListProcessing extends NtRegisterState {
  NtDanhSachQtxlModel danhSachQtxlModel;
  NtRegisterLoadedListProcessing(this.danhSachQtxlModel);
}

class NtRegisterLoadedListDoiTuongUuTien extends NtRegisterState {
  NtDanhSachDoiTuongUuTienModel danhSachDoiTuongUuTienModel;
  NtRegisterLoadedListDoiTuongUuTien(this.danhSachDoiTuongUuTienModel);
}

class NtRegisterLoadedListTrungTamLuuTru extends NtRegisterState {
  NtDanhSachTrungTamLuuTruModel danhSachTrungTamLuuTruModel;
  NtRegisterLoadedListTrungTamLuuTru(this.danhSachTrungTamLuuTruModel);
}

class NtRegisterLoadedListDanhSachLoaiPhong extends NtRegisterState {
  NtDanhSachPhongModel danhSachPhongModel;
  NtRegisterLoadedListDanhSachLoaiPhong(this.danhSachPhongModel);
}

class NtRegisterLoadedListDanhSachDotDangKy extends NtRegisterState {
  NtDanhSachDotDangKyLuuTruModel danhSachDotDangKyLuuTruModel;
  NtRegisterLoadedListDanhSachDotDangKy(this.danhSachDotDangKyLuuTruModel);
}

class NtRegisterSavedSuccess extends NtRegisterState {
  String message;
  NtRegisterSavedSuccess(this.message);
}

class NtRegisterLoadPhieuDangKySuccess extends NtRegisterState {
  List<PhieuDangKyNoiTruModel> phieuDangky;
  NtRegisterLoadPhieuDangKySuccess(this.phieuDangky);
}
