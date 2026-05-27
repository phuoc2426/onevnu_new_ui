import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreNewsDetailController extends GetxController {
  BuildContext? context;

  Rxn<TinTucModel> tintuc = Rxn();

  RxList<TinTucModel> listTinTucCungChuyenMuc = RxList([]);

  RxBool isLoadingTinTuc = false.obs;

  ScrollController scrollController = ScrollController();

  getDetailNew(String guid) async {
    if (guid.isEmpty) {
      logError('GUID null or empty');
      return;
    }
    Utils.showProgress(context);
    try {
      var response = await ApiRepository().getDetailTinTuc(guid);
      viewTinTuc(response);
      Utils.dismissProgress(context);
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  viewTinTuc(TinTucModel? tinTucModel) {
    if (tinTucModel == null) {
      return;
    }

    tintuc.value = tinTucModel;
    //update();
    loadTinTucCungChuyenMuc(tinTucModel.guidChuyenMucTinTuc);
  }

  loadTinTucCungChuyenMuc(String? guidChuyenMuc) async {
    if (guidChuyenMuc == null) {
      return;
    }
    //
    isLoadingTinTuc.value = true;
    try {
      var response = await ApiRepository()
          .getTinTucCungChuyenMuc(1, 10, 'created,desc', guidChuyenMuc);

      //Filter remove current news
      List<TinTucModel> listNews = (response.data ?? []);
      listNews.removeWhere((item) {
        return item.guid == tintuc.value?.guid;
      });

      listTinTucCungChuyenMuc.value = listNews;

      await scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn);

      isLoadingTinTuc.value = false;
    } catch (e) {
      isLoadingTinTuc.value = false;
      snackBarError(e.toString());
    }
  }

  downloadAndShare(String? guid, String tenFileDinhKem) async {
    if ((guid ?? '').isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }
    Utils.showProgress(context);

    String url = '${ServicesUrl().baseUrlFileDownload}$guid';

    try {
      File? file = await VnuCacheManager.downloadAndCache(
          url, guid ?? '', tenFileDinhKem.fileExtension());
      Utils.dismissProgress(context);

      if (file != null) {
        logSuccess(file.path);
        final result = await Share.shareXFiles([XFile(file.path)],
            subject: tenFileDinhKem);

        if (result.status == ShareResultStatus.success) {
          debugPrint('Thank you for sharing the data!');
        }
      } else {
        snackBarError(kMessageError);
      }
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }
}
