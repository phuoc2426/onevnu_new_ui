import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/services/services_url.dart';

part 'file_state.dart';

class FileCubit extends Cubit<FileState> {
  FileCubit() : super(FileInitial());

  /// GET FILE, pdf only
  getDetailFileId(String guidFile) async {
    emit(FileLoadingState());
    try {
      String previewUrl = '${ServicesUrl().baseUrlFileDownload}$guidFile';

      String name = "$guidFile.pdf";

      File? file =
          await VnuCacheManager.downloadAndCache(previewUrl, guidFile, 'pdf');

      if (file != null) {
        logSuccess(file.path);
        emit(FileLoadedSuccessState(file.path));
      } else {
        emit(FileLoadedErrorState(kMessageError));
      }
    } on DioException catch (e) {
      emit(FileLoadedErrorState(e.toString()));
    } catch (e) {
      emit(FileLoadedErrorState(e.toString()));
    }
  }
}
