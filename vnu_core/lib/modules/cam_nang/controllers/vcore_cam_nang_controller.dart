import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcoreCamNangController extends GetxController {
  BuildContext? context;

  RefreshController refreshController = RefreshController();
  TextEditingController textEditingController = TextEditingController();

  RxList<CamNangModel> listCamNang = RxList([]);

  int pageIndex = 1;
  int pageSize = 20;
  var isLoadMoreEnable = true;

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  refreshData() {
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
      var response = await ApiRepository().getCamNang(pageIndex, pageSize,
          'created,desc', textEditingController.text.trim());
      if (pageIndex == 1) {
        listCamNang.value = response.data ?? [];
      } else {
        listCamNang.addAll(response.data ?? []);
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
}
