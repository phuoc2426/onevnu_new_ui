import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcoreTimeScheduleController extends GetxController {
  BuildContext? context;

  RxList<String> danhSachKieuTruong = RxList([]);
  Rxn<String> kieuTruong = Rxn();

  RxList<HocKyModel> danhSachHocKy = RxList([]);
  Rxn<HocKyModel> hocKy = Rxn();

  //For list data
  RxList<LichThiHocKyModel> lichThiHocKy = RxList([]);

  RxMap<String, List<LichThiHocKyModel>> mapLichThiHocKy = RxMap();

  RxBool isTheoChuongTrinhDaoTao = true.obs;

  RefreshController refreshController = RefreshController();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  getDanhSachKieuTruong() async {
    kieuTruong.value = null;
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getDanhSachKieuTruong();
      Utils.dismissProgress(context);

      danhSachKieuTruong.value = response;
      if (danhSachKieuTruong.isNotEmpty) {
        kieuTruong.value = danhSachKieuTruong.firstWhereOrNull((obj) {
              return obj == "TruongChinh";
            }) ??
            danhSachKieuTruong.first;
        getDanhSachHocKy();
      }
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  getDanhSachHocKy() async {
    hocKy.value = null;
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getDanhSachHocKyTheoLichThi(
          isTheoChuongTrinhDaoTao.value, kieuTruong.value ?? '');
      Utils.dismissProgress(context);

      danhSachHocKy.value = response;
      if (danhSachHocKy.isNotEmpty) {
        hocKy.value = danhSachHocKy.first;
      }
      refreshData();
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  changeHocKy(String? displayName) {
    HocKyModel? obj = danhSachHocKy.firstWhereOrNull(
        (element) => element.disPlayName() == (displayName ?? "_///_"));
    if (obj != null) {
      hocKy.value = obj;
      refreshData();
    }
  }

  refreshData() {
    _loadData();
  }

  loadMoreData() {
    _loadData();
  }

  _loadData() async {
    lichThiHocKy.value = [];
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getLichThiHocKy(
        hocKy.value?.id ?? '',
        kieuTruong.value ?? '',
      );
      lichThiHocKy.value = response;

      //Convert to Map ngayThi - List<>
      Map<String, List<LichThiHocKyModel>> dict = {};
      for (var item in response) {
        if (item.ngayThi != null) {
          //1. check trung ngay trong lich
          if (dict.keys.contains(item.ngayThi)) {
            var newList =
                List<LichThiHocKyModel>.from(dict[item.ngayThi] ?? []);
            newList.add(item);
            dict[item.ngayThi ?? ''] = newList;
          } else {
            dict[item.ngayThi ?? ''] = [item];
          }
        }
      }

      mapLichThiHocKy.value = dict;

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
