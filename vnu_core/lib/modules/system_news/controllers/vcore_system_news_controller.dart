import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreSystemNewsController extends GetxController {
  BuildContext? context;

  TextEditingController textEditingController = TextEditingController();

  final RefreshController refreshController = RefreshController();
  Rxn<DateTime> startDate = Rxn();
  Rxn<DateTime> endDate = Rxn();

  RxBool isFilter = false.obs;

  RxList<TinHeThongModel> listTinTuc = RxList([]);

  int pageIndex = 1;
  int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    textEditingController.dispose();
    refreshController.dispose();
    super.onClose();
  }

  refreshData() {
    if (startDate.value != null || endDate.value != null) {
      isFilter.value = true;
    } else {
      isFilter.value = false;
    }
    pageIndex = 1;
    _loadData();
  }

  loadMoreData() {
    pageIndex += 1;
    _loadData();
  }

  _loadData() async {
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getTinHeThong(
        pageIndex,
        pageSize,
        'created,desc',
        textEditingController.text.trim(),
        startDate.value?.toUtc().toIso8601String() ?? '',
        endDate.value?.toUtc().toIso8601String() ?? '',
      );
      if (pageIndex == 1) {
        listTinTuc.value = response.data ?? [];
      } else {
        listTinTuc.addAll(response.data ?? []);
      }

      refreshController.refreshCompleted();
      refreshController.loadComplete();
      Utils.dismissProgress(context);
    } catch (e) {
      snackBarError(e.toString());
      refreshController.refreshCompleted();

      Utils.dismissProgress(context);
      refreshController.loadComplete();
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
