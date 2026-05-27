import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/thu_tuc_mot_cua_model.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreOneDoorDetailController extends GetxController {
  BuildContext? context;

  downloadHoSoAndShare(ThanhPhanHoSo hoso) async {
    if (hoso.guidFileDinhKems?.first != null && hoso.tenFileDinhKem != null) {
      Utils.showProgress(context);

      String url =
          '${ServicesUrl().baseUrlFileDownload}${hoso.guidFileDinhKems?.first}';

      String guid = hoso.guidFileDinhKems!.first;
      try {
        File? file = await VnuCacheManager.downloadAndCache(
            url, guid, hoso.tenFileDinhKem!.fileExtension());
        Utils.dismissProgress(context);

        if (file != null) {
          logSuccess(file.path);
          final result = await Share.shareXFiles([XFile(file.path)],
              subject: hoso.tenFileDinhKem);

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
    } else {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      logError("File null, name nulll....");
    }
  }
}
