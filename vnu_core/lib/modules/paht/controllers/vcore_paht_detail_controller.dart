import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/models/phan_anh_hien_truong_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';

class VcorePahtDetailController extends GetxController {
  BuildContext? context;

  Rxn<PhanAnhHienTruongModel> model = Rxn();
  Rxn<PhanAnhHienTruongXuLyModel> xylyModel = Rxn();

  RxBool enableDelete = false.obs;

  configWithModel(PhanAnhHienTruongModel paht) {
    model.value = paht;
    getDetailPaht();
    getResultProcess();
  }

  getDetailPaht() async {
    try {
      model.value = await ApiRepository().getPaht(model.value?.guid ?? '');
    } catch (e) {
      Get.back();
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getResultProcess() async {
    try {
      xylyModel.value =
          await ApiRepository().getPahtThongTinXuLy(model.value?.guid ?? '');
      enableDelete = false.obs;
    } catch (e) {
      logError(e.toString());
      enableDelete = true.obs;
      //snackBarError(e.toString());
    }
  }

  deletePaht() async {
    String guid = model.value?.guid ?? '';
    if (guid.isEmpty) {
      snackBarWarning('Không tìm thấy thông tin phản ánh.');
      return;
    }

    Utils.showProgress(context);
    try {
      var _ = await ApiRepository().deletePaht(guid);
      Utils.dismissProgress(context);
      Get.back(result: true);
      snackBarSuccess(
          'Xoá phản ánh "${model.value?.tieuDePhanAnh}" thành công.');
    } catch (e) {
      Utils.dismissProgress(context);
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  downloadAndOpen(FileDinhKemModel model) async {
    // down and open
    String guid = model.guid ?? '';
    String tenFileDinhKem = model.name ?? '';

    if (guid.isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }
    Utils.showProgress(context, withoutBinding: true);

    String url = '${ServicesUrl().baseUrlFileDownload}$guid';

    try {
      File? file = await VnuCacheManager.downloadAndCache(
          url, guid, model.extension ?? tenFileDinhKem.fileExtension());
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

  downloadAndShare(String? guid, String tenFileDinhKem) {
    if ((guid ?? '').isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }
    Utils.showProgress(context, withoutBinding: true);

    String url = '${ServicesUrl().baseUrlFileDownload}$guid';
    DownLoadManager().downloadFile(
      url,
      tenFileDinhKem,
      DownloadMode.PreviewTemp,
      guid: guid!,
      onComplete: (urlComplete) async {
        logSuccess(urlComplete);
        Utils.dismissProgress(context);
        final result = await Share.shareXFiles([XFile(urlComplete)],
            subject: tenFileDinhKem);

        if (result.status == ShareResultStatus.success) {
          debugPrint('Thank you for sharing the data!');
        }
      },
      onError: (e) {
        Utils.dismissProgress(context);
        snackBarError(e);
      },
    );
  }
}
