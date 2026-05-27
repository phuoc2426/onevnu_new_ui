import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/don_vi_model.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreNewsController extends GetxController {
  BuildContext? context;

  TextEditingController textEditingController = TextEditingController();

  final RefreshController refreshController = RefreshController();

  RxList<DonViModel> listDonVi = RxList([]);
  Rxn<DonViModel> currentDonVi = Rxn();
  Rxn<DateTime> startDate = Rxn();
  Rxn<DateTime> endDate = Rxn();

  RxBool isFilter = false.obs;

  RxList<TinTucModel> listTinTuc = RxList([]);

  int pageIndex = 1;
  int pageSize = 10;

  @override
  void onInit() {
    super.onInit();

    getTatCaDonVi();
  }

  @override
  void onClose() {
    textEditingController.dispose();
    refreshController.dispose();
    super.onClose();
  }

  getTatCaDonVi() async {
    try {
      var response = await ApiRepository().getTatCaDonVi();
      listDonVi.value = response;
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  refreshData() {
    if (currentDonVi.value != null ||
        startDate.value != null ||
        endDate.value != null) {
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
    if (pageIndex == 1) {
      Utils.showProgress(context);
    }

    try {
      var response = await ApiRepository().getTinTuc(
        pageIndex,
        pageSize,
        'created,desc',
        textEditingController.text.trim(),
        currentDonVi.value?.guid ?? '',
        startDate.value?.toUtc().toIso8601String() ?? '',
        endDate.value?.toUtc().toIso8601String() ?? '',
        '',
      );
      if (pageIndex == 1) {
        listTinTuc.value = response.data ?? [];
      } else {
        listTinTuc.addAll(response.data ?? []);
      }

      refreshController.refreshCompleted();
      refreshController.loadComplete();
    } catch (e) {
      snackBarError(e.toString());
      refreshController.refreshCompleted();
      refreshController.loadComplete();
    }

    if (pageIndex == 1) {
      Utils.dismissProgress(context);
    }
  }
}
