import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/lien_ket_danh_dau_model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreBookmarkController extends GetxController {
  BuildContext? context;

  TextEditingController textEditingController = TextEditingController();
  RefreshController refreshController = RefreshController();

  RxList<LienKetDanhDauModel> listLienKetDanhDau = RxList([]);

  int pageIndex = 1;
  int pageSize = 20;

  TextEditingController editTitleController = TextEditingController();

  @override
  void dispose() {
    refreshController.dispose();
    textEditingController.dispose();
    editTitleController.dispose();
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
      var response = await ApiRepository().getLienKetDanhDau(
        pageIndex,
        pageSize,
        'created,desc',
        textEditingController.text.trim(),
      );
      if (pageIndex == 1) {
        listLienKetDanhDau.value = response.data ?? [];
      } else {
        listLienKetDanhDau.addAll(response.data ?? []);
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

  updateTitle(LienKetDanhDauModel model, String title) async {
    try {
      Utils.showProgress(context);
      var _ = await ApiRepository()
          .updateLienKetDanhDau(model.guid ?? '', title, model.lienKet ?? '');

      model.tenLienKet = title;
      Utils.dismissProgress(context);
      snackBarSuccess('Cập nhật tiêu đề thành công');
      update();
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
    }
  }

  deleteLienKet(LienKetDanhDauModel model) {
    Utils.showAlertDialog(context, "Xoá liên kết",
        "Bạn có chắc chắn muốn xoá liên kết: ${model.tenLienKet}",
        okStr: "Xác nhận",
        cancelStr: "Đóng",
        withoutBinding: true, callBackOK: () {
      _excDeleteLienKet(model);
    });
  }

  _excDeleteLienKet(LienKetDanhDauModel model) async {
    try {
      Utils.showProgress(context);
      var _ = await ApiRepository().deleteLienKetDanhDau(model.guid ?? '');

      Utils.dismissProgress(context);
      snackBarSuccess('Xoá liên kết thành công');
      listLienKetDanhDau.removeWhere((item) => item.guid == model.guid);
      update();
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
    }
  }
}
