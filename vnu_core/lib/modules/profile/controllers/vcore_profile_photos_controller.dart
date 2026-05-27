import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreProfilePhotosController extends GetxController {
  BuildContext? context;

  RxList<AnhCaNhanModel> listAnhCaNhan = RxList([]);

  RefreshController refreshController = RefreshController();

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  refreshData() async {
    try {
      var response = await ApiRepository().getAllAnhCanNhan();

      listAnhCaNhan.value = response;
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  pickPhoto() async {
    //
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      logSuccess('Pick file success...');
      //Upload file
      Utils.showProgress(context);
      try {
        var response = await ApiRepository().uploadAnhCanNhan(
          File(image.path),
        );

        listAnhCaNhan.add(response);
        Utils.dismissProgress(context);
      } catch (e) {
        Utils.dismissProgress(context);
        snackBarError(e.toString());
      }
    } else {
      // User canceled the picker
      logError('Pick file error...');
    }
  }

  deleteAnhCaNhan(AnhCaNhanModel image) async {
    if ((image.guid ?? '').isEmpty) {
      return;
    }
    try {
      var _ = await ApiRepository().deleteAnhCanNhan(image.guid ?? '');
      listAnhCaNhan.remove(image);
    } catch (e) {
      snackBarError(e.toString());
    }
  }
}
