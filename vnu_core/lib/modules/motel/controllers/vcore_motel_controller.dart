import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/data/api_response.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcoreMotelController extends GetxController {
  BuildContext? context;
  RefreshController refreshController = RefreshController();

  RxList<PhongTroModel> listPhongTro = RxList([]);

  RxList<KhuVucBanDoModel> listKhuVuc = RxList([]);
  Rxn<KhuVucBanDoModel> currentKhuVuc = Rxn();

  KhuVucBanDoModel allKhuVuc =
      KhuVucBanDoModel(tenKhuVucBanDo: 'Tất cả', guid: '');

  int pageIndex = 1;
  int pageSize = 10;
  var isLoadMoreEnable = true;

  @override
  void onInit() {
    super.onInit();
    listKhuVuc.value = [allKhuVuc];
    currentKhuVuc.value = allKhuVuc;
    getTatKhuVucBanDo();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  getTatKhuVucBanDo() async {
    try {
      var response = await ApiRepository().getTatKhuVucBanDo();
      listKhuVuc.addAll(response);
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  changeKhuVuc(KhuVucBanDoModel khuVuc) {
    currentKhuVuc.value = khuVuc;
    refreshData();
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
      ApiResponse<List<PhongTroModel>> response =
          await ApiRepository().getPhongTro(
        pageIndex,
        pageSize,
        'created,desc',
        currentKhuVuc.value?.guid ?? '',
      );

      if (pageIndex == 1) {
        listPhongTro.value = response.data ?? [];
      } else {
        listPhongTro.addAll(response.data ?? []);
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
