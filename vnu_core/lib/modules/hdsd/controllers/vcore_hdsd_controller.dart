import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcoreHdsdController extends GetxController {
  BuildContext? context;

  RxList<HdsdModel> listHdsd = RxList([]);

  RefreshController refreshController = RefreshController();

  int pageIndex = 1;
  int pageSize = 20;
  var isLoadMoreEnable = true;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  refreshData() async {
    Utils.showProgress(context);
    try {
      var response = await ApiRepository().getHuongDanSuDung();
      listHdsd.value = response;
      Utils.dismissProgress(context);
      refreshController.refreshCompleted();
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
      refreshController.refreshCompleted();
    }
  }

  loadMoreData() {}
}
