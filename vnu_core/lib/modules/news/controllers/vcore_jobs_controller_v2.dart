import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreJobsControllerV2 extends GetxController {
  BuildContext? context;

  final TextEditingController textEditingController = TextEditingController();
  final RefreshController refreshController = RefreshController();

  RxList<TinTucModel> listJobs = RxList([]);

  int pageIndex = 1;
  int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    textEditingController.dispose();
    refreshController.dispose();
    super.onClose();
  }

  void refreshData() {
    pageIndex = 1;
    _loadData();
  }

  void loadMoreData() {
    pageIndex += 1;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      Utils.showProgress(context);
      // Calls getTinTuc with the Jobs category GUID: 6b12cbb2-8148-46a8-a449-f1ba6530242a
      final response = await ApiRepository().getTinTuc(
        pageIndex,
        pageSize,
        'created,desc',
        textEditingController.text.trim(),
        '', // guidDonViPhatHanh
        '', // thoiGianStart
        '', // thoiGianEnd
        '6b12cbb2-8148-46a8-a449-f1ba6530242a', // guidChuyenMuc (Việc làm)
      );

      final List<TinTucModel> newData = response.data ?? [];
      if (pageIndex == 1) {
        listJobs.assignAll(newData);
      } else {
        listJobs.addAll(newData);
      }

      refreshController.refreshCompleted();
      if (newData.length >= pageSize) {
        refreshController.loadComplete();
      } else {
        refreshController.loadNoData();
      }
      Utils.dismissProgress(context);
    } catch (e) {
      logError("VcoreJobsControllerV2 _loadData error: $e");
      snackBarError(e.toString());
      refreshController.refreshCompleted();
      refreshController.loadComplete();
      Utils.dismissProgress(context);
    }
  }
}
