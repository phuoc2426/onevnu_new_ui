import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/data/api_response.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcorePahtComunitationControllerV2 extends GetxController {
  BuildContext? context;
  final RefreshController refreshController = RefreshController();

  final RxList<KhuVucBanDoModel> listKhuVuc = RxList<KhuVucBanDoModel>([]);
  final Rxn<KhuVucBanDoModel> currentKhuVuc = Rxn<KhuVucBanDoModel>();
  final KhuVucBanDoModel allKhuVuc = KhuVucBanDoModel(tenKhuVucBanDo: 'Tất cả', guid: '');

  final RxList<PhanAnhHienTruongChuDeModel> listChuDe = RxList<PhanAnhHienTruongChuDeModel>([]);
  final Rxn<PhanAnhHienTruongChuDeModel> currentChuDe = Rxn<PhanAnhHienTruongChuDeModel>();
  final PhanAnhHienTruongChuDeModel allChuDe = PhanAnhHienTruongChuDeModel(guid: '', tenChuDe: 'Tất cả chủ đề');

  final RxList<PhanAnhHienTruongModel> listPaht = RxList<PhanAnhHienTruongModel>([]);
  final RxBool isLoading = false.obs;

  int pageIndex = 1;
  int pageSize = 10;

  @override
  void onInit() {
    super.onInit();
    listKhuVuc.value = [allKhuVuc];
    currentKhuVuc.value = allKhuVuc;
    listChuDe.value = [allChuDe];
    currentChuDe.value = allChuDe;
    getTatKhuVucBanDo();
    getTatCaChuDe();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  Future<void> getTatKhuVucBanDo() async {
    try {
      final response = await ApiRepository().getTatKhuVucBanDo();
      listKhuVuc.value = [allKhuVuc, ...response];
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  void changeKhuVuc(KhuVucBanDoModel khuVuc) {
    currentKhuVuc.value = khuVuc;
    refreshData();
  }

  Future<void> getTatCaChuDe() async {
    try {
      final response = await ApiRepository().getPahtTatCaChuDe();
      listChuDe.value = [allChuDe, ...response];
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  void changeChuDe(VcoreDropdownModel model) {
    final obj = listChuDe.firstWhereOrNull((element) => element.guid == model.guid);
    if (obj != null) {
      currentChuDe.value = obj;
      refreshData();
    }
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
      final ApiResponse<List<PhanAnhHienTruongModel>> response = await ApiRepository().getPahtCongDong(
        currentChuDe.value?.guid ?? '',
        currentKhuVuc.value?.guid ?? '',
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
