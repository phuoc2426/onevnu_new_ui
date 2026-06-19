import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/data/api_response.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcorePahtSearchControllerV2 extends GetxController {
  BuildContext? context;
  final TextEditingController textEditingController = TextEditingController();
  final RefreshController refreshController = RefreshController();
  final RxBool isLoading = false.obs;
  final RxList<PhanAnhHienTruongModel> listPaht = RxList<PhanAnhHienTruongModel>([]);

  int pageIndex = 1;
  int pageSize = 10;

  @override
  void onClose() {
    textEditingController.dispose();
    refreshController.dispose();
    super.onClose();
  }

  Future<void> refreshData() async {
    pageIndex = 1;
    await _loadData();
  }

  Future<void> loadMoreData() async {
    pageIndex += 1;
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      isLoading.value = true;
      Utils.showProgress(context);
      final ApiResponse<List<PhanAnhHienTruongModel>> response = await ApiRepository().searchPaht(
        textEditingController.text.trim(),
        pageIndex,
        pageSize,
        'created,desc',
      );

      final data = response.data ?? [];
      if (pageIndex == 1) {
        listPaht.value = data;
      } else {
        listPaht.addAll(data);
      }

      refreshController.refreshCompleted();
      refreshController.loadComplete();
      Utils.dismissProgress(context);
      isLoading.value = false;
    } catch (e) {
      snackBarError(e.toString());
      refreshController.refreshCompleted();
      refreshController.loadComplete();
      Utils.dismissProgress(context);
      isLoading.value = false;
    }
  }
}
