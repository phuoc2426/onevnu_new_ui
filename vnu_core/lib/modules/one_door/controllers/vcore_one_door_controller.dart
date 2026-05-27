import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/linh_vuc_model.dart';
import 'package:vnu_core/models/thu_tuc_mot_cua_model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreOneDoorController extends GetxController {
  BuildContext? context;
  TextEditingController textEditingController = TextEditingController();

  RefreshController refreshController = RefreshController();

  RxList<LinhVucModel> listLinhVuc = RxList([]);
  Rxn<LinhVucModel> currentLinhVuc = Rxn();

  RxList<ThuTucMotCuaModel> listThuTucMotCua = RxList([]);

  final allLinhVuc = LinhVucModel(
      tenLinhVuc: 'Tất cả lĩnh vực', guid: '', moTa: 'Tất cả lĩnh vực');

  int pageIndex = 1;
  int pageSize = 20;
  var isLoadMoreEnable = true;

  @override
  void onInit() {
    super.onInit();
    listLinhVuc.value = [allLinhVuc];
    currentLinhVuc.value = allLinhVuc;

    getTatCaLinhVuc();
  }

  getTatCaLinhVuc() async {
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getTatCaLinhVucTTMC();
      listLinhVuc.addAll(response);

      refreshData();
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
    }
  }

  @override
  void dispose() {
    refreshController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  changeLinhVuc(String? title) {
    LinhVucModel? obj = listLinhVuc.firstWhereOrNull(
        (element) => element.tenLinhVuc == (title ?? "_///_"));
    if (obj != null) {
      currentLinhVuc.value = obj;
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
      var response = await ApiRepository().getThuTucMotCua(
          pageIndex,
          pageSize,
          'created,desc',
          textEditingController.text.trim(),
          currentLinhVuc.value?.guid ?? '');
      if (pageIndex == 1) {
        listThuTucMotCua.value = response.data ?? [];
      } else {
        listThuTucMotCua.addAll(response.data ?? []);
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
