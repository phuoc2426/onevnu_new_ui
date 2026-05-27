import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/cau_tra_loi_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreQuestionDetailController extends GetxController {
  BuildContext? context;

  RxBool isLoadingAnswer = true.obs;
  Rxn<CauTraLoiModel> cauTraLoi = Rxn();

  @override
  void onInit() {
    super.onInit();
  }

  getCauTraLoi(String guid) async {
    if (guid.isEmpty) {
      snackBarError('Không tìm thấy câu hỏi.');
      isLoadingAnswer.value = false;
      return;
    }
    try {
      isLoadingAnswer.value = true;
      var response = await ApiRepository().getCauTraLoi(guid);

      isLoadingAnswer.value = false;
      cauTraLoi.value = response;
    } catch (e) {
      isLoadingAnswer.value = false;
      //snackBarError(e.toString());
    }
  }

  deleteQuestion(String? guid) async {
    if ((guid ?? '').isEmpty) {
      snackBarError('Không tìm thấy thông tin câu hỏi.');
      return;
    }
    Utils.showProgress(context);
    try {
      var _ = await ApiRepository().deleteCauTraLoi(guid ?? '');
      Utils.dismissProgress(context);
      Get.back(result: true, closeOverlays: true);
      snackBarSuccess('Xoá câu hỏi thành công');
    } catch (e) {
      Utils.dismissProgress(context);
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
