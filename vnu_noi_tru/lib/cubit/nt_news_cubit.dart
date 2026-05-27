import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_noi_tru/repository/noitru_repository.dart';
import 'package:dio/dio.dart';
import '../models/model.dart';

part 'nt_news_state.dart';

class NtNewsCubit extends Cubit<NtNewsState> {
  NtNewsCubit() : super(NtNewsInitial());

  getDanhSachTinTuc(
    int? ID_ChuyenMuc,
    int PageNumber,
    int PageSize,
  ) async {
    if (PageNumber <= 1) {
      emit(NtNewsLoading());
    }
    try {
      var response = await NoiTruRepository().getDanhSachTinTuc(
          ID_ChuyenMuc == null ? "" : "$ID_ChuyenMuc", PageNumber, PageSize);
      emit(NtNewsLoadedListSuccess(
          response.data.danhSachTinTuc ?? [], PageNumber));
    } on DioException catch (e) {
      emit(NtNewsLoadedError(e.toString()));
    } catch (e) {
      emit(NtNewsLoadedError(e.toString()));
    }
  }

  getDanhSachThongBao(
    String TrangThai,
    int PageNumber,
    int PageSize,
  ) async {
    if (PageNumber <= 1) {
      emit(NtNewsLoading());
    }
    try {
      var response = await NoiTruRepository()
          .getDanhSachThongBao(TrangThai, PageNumber, PageSize);
      emit(NtNewsLoadedListThongBaoSuccess(
          response.data.danhSachThongBao ?? [], PageNumber));
    } on DioException catch (e) {
      emit(NtNewsLoadedError(e.toString()));
    } catch (e) {
      emit(NtNewsLoadedError(e.toString()));
    }
  }

  danhDauDaDocThongBao(
    int id,
  ) async {
    try {
      var response = await NoiTruRepository().danhDauDaDoc(id);
    } on DioException catch (e) {
      logError(e.toString());
    } catch (e) {
      logError(e.toString());
    }
  }
}
