import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/data/api_response.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcorePahtComunitationController extends GetxController {
  BuildContext? context;
  RefreshController refreshController = RefreshController();

  // Khu vuc
  RxList<KhuVucBanDoModel> listKhuVuc = RxList([]);
  Rxn<KhuVucBanDoModel> currentKhuVuc = Rxn();

  KhuVucBanDoModel allKhuVuc =
      KhuVucBanDoModel(tenKhuVucBanDo: 'Tất cả', guid: '');

  // Chủ đề
  RxList<PhanAnhHienTruongChuDeModel> listChuDe = RxList([]);
  Rxn<PhanAnhHienTruongChuDeModel> currentChuDe = Rxn();
  PhanAnhHienTruongChuDeModel allChuDe =
      PhanAnhHienTruongChuDeModel(guid: '', tenChuDe: 'Tất cả chủ đề');

  // Danh sach ket qua
  RxList<PhanAnhHienTruongModel> listPaht = RxList([]);

  int pageIndex = 1;
  int pageSize = 10;
  var isLoadMoreEnable = true;

  @override
  void onInit() {
    super.onInit();
    listKhuVuc.value = [allKhuVuc];
    currentKhuVuc.value = allKhuVuc;
    getTatKhuVucBanDo();

    listChuDe.value = [allChuDe];
    currentChuDe.value = allChuDe;
    getTatCaChuDe();
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

  getTatCaChuDe() async {
    try {
      var response = await ApiRepository().getPahtTatCaChuDe();
      listChuDe.addAll(response);
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  changeChuDe(VcoreDropdownModel model) {
    PhanAnhHienTruongChuDeModel? obj =
        listChuDe.firstWhereOrNull((element) => element.guid == model.guid);
    if (obj != null) {
      currentChuDe.value = obj;
      refreshData();
    }
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
      ApiResponse<List<PhanAnhHienTruongModel>> response =
          await ApiRepository().getPahtCongDong(
        currentChuDe.value?.guid ?? '',
        currentKhuVuc.value?.guid ?? '',
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
    } catch (e) {
      snackBarError(e.toString());
      refreshController.refreshCompleted();

      Utils.dismissProgress(context);
      refreshController.loadComplete();
    }
  }
}
