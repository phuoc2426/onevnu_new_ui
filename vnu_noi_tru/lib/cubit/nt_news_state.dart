part of 'nt_news_cubit.dart';

@immutable
abstract class NtNewsState {}

class NtNewsInitial extends NtNewsState {}

class NtNewsLoading extends NtNewsState {}

class NtNewsShowHub extends NtNewsState {}

class NtNewsDismissHub extends NtNewsState {}

class NtNewsLoadedError extends NtNewsState {
  String message;
  NtNewsLoadedError(this.message);
}

class NtNewsLoadedListSuccess extends NtNewsState {
  List<NtTinTucModel> danhSachTinTuc;
  int pageNumber;
  NtNewsLoadedListSuccess(this.danhSachTinTuc, this.pageNumber);
}

class NtNewsLoadedListThongBaoSuccess extends NtNewsState {
  List<DanhSachThongBao> danhSachThongBao;
  int pageNumber;
  NtNewsLoadedListThongBaoSuccess(this.danhSachThongBao, this.pageNumber);
}
