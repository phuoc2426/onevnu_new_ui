import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/models/phan_anh_hien_truong_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/constants/enum.dart';

class VcorePahtDetailControllerV2 extends GetxController {
  BuildContext? context;

  final Rxn<PhanAnhHienTruongModel> model = Rxn<PhanAnhHienTruongModel>();
  final Rxn<PhanAnhHienTruongXuLyModel> xylyModel =
      Rxn<PhanAnhHienTruongXuLyModel>();
  final RxBool enableDelete = false.obs;
  String? _loadedGuid;

  void configWithModel(PhanAnhHienTruongModel paht) {
    final guid = paht.guid ?? '';
    if (_loadedGuid == guid && model.value != null) return;
    _loadedGuid = guid;
    model.value = paht;
    getDetailPaht();
    getResultProcess();
  }

  Future<void> getDetailPaht() async {
    try {
      model.value = await ApiRepository().getPaht(model.value?.guid ?? '');
    } catch (e) {
      Get.back();
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  Future<void> getResultProcess() async {
    try {
      xylyModel.value = await ApiRepository().getPahtThongTinXuLy(
        model.value?.guid ?? '',
      );
      enableDelete.value = false;
    } catch (e) {
      logError(e.toString());
      enableDelete.value = true;
    }
  }

  Future<void> deletePaht() async {
    final guid = model.value?.guid ?? '';
    if (guid.isEmpty) {
      snackBarWarning('Không tìm thấy thông tin phản ánh.');
      return;
    }

    Utils.showProgress(context);
    try {
      await ApiRepository().deletePaht(guid);
      Utils.dismissProgress(context);
      Get.back(result: true);
      snackBarSuccess(
        'Xoá phản ánh "${model.value?.tieuDePhanAnh}" thành công.',
      );
    } catch (e) {
      Utils.dismissProgress(context);
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  Future<void> downloadAndOpen(dynamic fileModel) async {
    final String guid = fileModel.guid ?? '';
    final String tenFileDinhKem = fileModel.name ?? '';

    if (guid.isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }
    Utils.showProgress(context, withoutBinding: true);

    final String url = '${ServicesUrl().baseUrlFileDownload}$guid';
    try {
      final File? file = await VnuCacheManager.downloadAndCache(
        url,
        guid,
        fileModel.extension ?? tenFileDinhKem.fileExtension(),
      );
      Utils.dismissProgress(context);
      if (file != null) {
        logSuccess(file.path);
        OpenFilex.open(file.path);
      } else {
        snackBarError(kMessageError);
      }
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  void downloadAndShare(String? guid, String tenFileDinhKem) {
    if ((guid ?? '').isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }
    Utils.showProgress(context, withoutBinding: true);

    final String url = '${ServicesUrl().baseUrlFileDownload}$guid';
    DownLoadManager().downloadFile(
      url,
      tenFileDinhKem,
      DownloadMode.PreviewTemp,
      guid: guid!,
      onComplete: (urlComplete) async {
        logSuccess(urlComplete);
        Utils.dismissProgress(context);
        await Share.shareXFiles([XFile(urlComplete)], subject: tenFileDinhKem);
      },
      onError: (e) {
        Utils.dismissProgress(context);
        snackBarError(e);
      },
    );
  }
}
