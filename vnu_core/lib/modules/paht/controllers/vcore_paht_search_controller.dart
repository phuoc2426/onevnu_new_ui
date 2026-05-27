import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/data/api_response.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcorePahtSearchController extends GetxController {
  BuildContext? context;

  TextEditingController textEditingController = TextEditingController();
  RefreshController refreshController = RefreshController();
  RxBool isLoading = false.obs;

  // Danh sach ket qua
  RxList<PhanAnhHienTruongModel> listPaht = RxList([]);

  int pageIndex = 1;
  int pageSize = 10;
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
      isLoading.value = true;
      Utils.showProgress(context);
      ApiResponse<List<PhanAnhHienTruongModel>> response =
          await ApiRepository().searchPaht(
        textEditingController.text.trim(),
        pageIndex,
        pageSize,
        'created,desc',
      );

      if (pageIndex == 1) {
        listPaht.value = response.data ?? [];
      } else {
        listPaht.addAll(response.data ?? []);
      }

      refreshController.refreshCompleted();
      refreshController.loadComplete();
      Utils.dismissProgress(context);

      isLoading.value = false;
    } catch (e) {
      snackBarError(e.toString());
      refreshController.refreshCompleted();

      Utils.dismissProgress(context);
      refreshController.loadComplete();

      isLoading.value = false;
    }
  }
}
