import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_noi_tru/data/requests/luu_noi_tru_request.dart';
import 'package:vnu_noi_tru/repository/noitru_dormitory_repository.dart';
import 'package:dio/dio.dart';
import '../models/model.dart';
part 'nt_register_state.dart';

class NtRegisterCubit extends Cubit<NtRegisterState> {
  NtRegisterCubit() : super(NtRegisterInitial());

  getDanhSachQuaTrinhXuLy(int maYeuCau) async {
    emit(NtRegisterShowHub());
    try {
      var response =
          await NoitruDormitoryRepository().getThongTinQuaTrinhXuLy(maYeuCau);
      emit(NtRegisterDismissHub());
      emit(NtRegisterLoadedListProcessing(response.data));
    } on DioException catch (e) {
      emit(NtRegisterDismissHub());
      emit(NtRegisterLoadedError(e.toString()));
    } catch (e) {
      emit(NtRegisterDismissHub());
      emit(NtRegisterLoadedError(e.toString()));
    }
  }

  getDanhSachDoiTuongUuTien() async {
    emit(NtRegisterLoading());
    try {
      var response =
          await NoitruDormitoryRepository().getDanhSachDoiTuongUuTien();
      emit(NtRegisterLoadedListDoiTuongUuTien(response.data));
    } on DioException catch (e) {
      emit(NtRegisterLoadedError(e.toString()));
      logError(e.toString());
    } catch (e) {
      logError(e.toString());
      emit(NtRegisterLoadedError(e.toString()));
    }
  }

  /// Danh sách ký túc xá
  getDanhSachTrungTamLuuTru() async {
    emit(NtRegisterLoading());
    try {
      var response =
          await NoitruDormitoryRepository().getDanhSachTrungTamLuuTru();
      emit(NtRegisterLoadedListTrungTamLuuTru(response.data));
    } on DioException catch (e) {
      emit(NtRegisterLoadedError(e.toString()));
      logError(e.toString());
    } catch (e) {
      logError(e.toString());
      emit(NtRegisterLoadedError(e.toString()));
    }
  }

  getDanhSachPhongCuaTrungTam(int ID_TrungTamLuuTru) async {
    emit(NtRegisterLoading());
    try {
      var response =
          await NoitruDormitoryRepository().getDanhSachPhong(ID_TrungTamLuuTru);
      emit(NtRegisterLoadedListDanhSachLoaiPhong(response.data));
    } on DioException catch (e) {
      emit(NtRegisterLoadedError(e.toString()));
      logError(e.toString());
    } catch (e) {
      logError(e.toString());
      emit(NtRegisterLoadedError(e.toString()));
    }
  }

  getDanhSachDotDangKy() async {
    emit(NtRegisterLoading());
    try {
      var response = await NoitruDormitoryRepository().getDanhSachDotDangKy();
      emit(NtRegisterLoadedListDanhSachDotDangKy(response.data));
    } on DioException catch (e) {
      logError(e.toString());
      emit(NtRegisterLoadedError(e.toString()));
    } catch (e) {
      logError(e.toString());
      emit(NtRegisterLoadedError(e.toString()));
    }
  }

  dangKyNoitru(
      List<DanhSachDoiTuongUuTien>? doiTuongUuTien,
      DanhSachDotDangKyLuuTru dotDangKyLuuTru,
      DanhSachTrungTamLuuTru trungTamLuuTru,
      DanhSachLoaiPhong loaiPhong,
      List<int> fileIds) async {
    String cmndCccd = await VnuCore().getLoginUserName() ?? '';
    logSuccess(cmndCccd);
    //TODO: - fix cccd
    // if (kDebugMode) {
    //   cmndCccd = '092014158';
    // }
    LuuNoiTruRequest request = LuuNoiTruRequest(
        cmndCccd: cmndCccd,
        idDoiTuongUuTien: doiTuongUuTien != null
            ? doiTuongUuTien
                .where((element) {
                  return (element.id != null);
                })
                .map((e) => e.id!)
                .toList()
            : [],
        idDotDangKy: dotDangKyLuuTru.id ?? -1,
        idTrungTamLuuTru: trungTamLuuTru.id ?? -1,
        idLoaiPhong: loaiPhong.id ?? -1,
        filesDinhKem: fileIds,
        trangThai: 1);
    emit(NtRegisterShowHub());
    try {
      var response =
          await NoitruDormitoryRepository().luuThongTinDangKy(request);
      // emit(NtRegisterLoadedListDanhSachDotDangKy(response.data));
      emit(NtRegisterDismissHub());
      if (response.resultCode == 0) {
        emit(
            NtRegisterSavedSuccess('Gửi thông tin đăng ký nội trú thành công'));
      } else {
        emit(NtRegisterLoadedError(response.resultMessage ?? kMessageError));
      }
    } on DioException catch (e) {
      logError(e.response.toString());
      emit(NtRegisterDismissHub());
      emit(NtRegisterLoadedError(e.toString()));
    } catch (e) {
      logError(e.toString());
      emit(NtRegisterDismissHub());
      emit(NtRegisterLoadedError(e.toString()));
    }
  }

  // Danh sách phiếu đã đăng ký
  getDanhSachPhieuDangKy() async {
    String cmndCccd = await VnuCore().getLoginUserName() ?? '';
    logSuccess(cmndCccd);
    //TODO: - fix cccd
    // if (kDebugMode) {
    //   cmndCccd = '030303001240';
    // }
    emit(NtRegisterShowHub());
    try {
      var response =
          await NoitruDormitoryRepository().getDanhSachPhieuDangKy(cmndCccd);
      emit(NtRegisterDismissHub());
      if (response.resultCode == 0) {
        logSuccess('Get Phieu dang ky thành công');
        emit(NtRegisterLoadPhieuDangKySuccess(response.data.phieuDangKy ?? []));
      } else {
        //
        logError(response.resultMessage ?? '');
        emit(NtRegisterLoadedError(response.resultMessage ?? ''));
        emit(NtRegisterLoadPhieuDangKySuccess(const []));
      }
    } catch (e) {
      emit(NtRegisterDismissHub());
      emit(NtRegisterLoadedError(e.toString()));
      emit(NtRegisterLoadPhieuDangKySuccess(const []));
    }
  }

  uploadFile(NtFileMinhChungModel fileModel, String prefixDTUU) async {
    emit(NtRegisterLoading());
    try {
      if (fileModel.file == null) {
        emit(NtRegisterUpLoadedError('Không tìm thấy file upload'));
        return;
      }
      // file.name
      //1. Get link file upload
      String fileName = "${prefixDTUU}_${fileModel.file!.name}";
      final extension =
          p.extension(fileModel.file!.name).replaceAll('.', ''); // '.dart'

      // double fileSize= fileModel.file.length()
      var response = await NoitruDormitoryRepository()
          .getUrlPresigned(fileName, extension, fileModel.fileSize ?? 2000000);
      if (response.data.fileId == null || response.data.uploadUrl == null) {
        emit(NtRegisterUpLoadedError('Tải file không thành công.'));
      } else {
        fileModel.fileMinhChungId = response.data.fileId;
        fileModel.urlUpload = response.data.uploadUrl;
        // 2. upload file to URL
        var dio = Dio(); // with default Options
        dio.options.headers.addAll({
          'cache-control': 'no-cache',
          'Content-Type': '',
        });

        File file = File(fileModel.file!.path);

        Uint8List fileData = file.readAsBytesSync();
        var responseUpload = await dio.put(
          response.data.uploadUrl!,
          //data: fileData
          data: Stream.fromIterable(fileData.map((e) => [e])),
          options: Options(
            headers: {
              Headers.contentLengthHeader:
                  fileData.length, // set content-length
            },
          ),
        );
        if (responseUpload.statusCode == 200) {
          logSuccess('UPlooad thanfh cong');
          fileModel.status = 1;
          emit(NtRegisterUpLoadedSuccess());
        } else {
          logError('Upload failed');
          emit(NtRegisterUpLoadedError(''));
        }
      }
    } catch (e) {
      logError(e.toString());
      emit(NtRegisterUpLoadedError(e.toString()));
    }
  }
}
