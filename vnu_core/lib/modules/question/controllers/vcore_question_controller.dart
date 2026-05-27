import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/weekdate_iso8601.dart';
import 'package:vnu_core/extensions/date_time_extension.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcoreQuestionController extends GetxController {
  BuildContext? context;
  String trangThai = '';

  RefreshController refreshController = RefreshController();

  RxList<ChuDeModel> listChuDe = RxList([]);
  Rxn<ChuDeModel> currentChuDe = Rxn();

  Rxn<DateTime> startDate = Rxn();
  Rxn<DateTime> endDate = Rxn();

  RxList<HoiDapModel> listQuestion = RxList([]);

  final allChuDe = ChuDeModel(tenChuDe: 'Tất cả chủ đề', guid: '');

  int pageIndex = 1;
  int pageSize = 10;
  var isLoadMoreEnable = true;

  @override
  void onInit() {
    super.onInit();
    listChuDe.value = [allChuDe];
    currentChuDe.value = allChuDe;

    getTatCaChuDe();
  }

  getTatCaChuDe() async {
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getTatChuDeHoiDap();
      listChuDe.addAll(response);
      Utils.dismissProgress(context);

      refreshData();
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
    }
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  changeChuDe(String? title) {
    ChuDeModel? obj = listChuDe
        .firstWhereOrNull((element) => element.tenChuDe == (title ?? "_///_"));
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

  changeDate(DateTime date, bool needRefreshData) {
    List<DateTime> dateOffWeek =
        Week8601(year: date.year, weekNumber: date.weekOfYear).days;
    startDate.value = dateOffWeek.first;
    endDate.value = dateOffWeek.last;
    if (needRefreshData) {
      refreshData();
    }
  }

  _loadData() async {
    try {
      if (kDebugMode) {
        logWarning(startDate.value?.toUtc().toIso8601String() ?? '');
        logWarning(endDate.value?.toUtc().toIso8601String() ?? '');
      }
      Utils.showProgress(context);
      var response = await ApiRepository().getCauHoiDap(
        pageIndex,
        pageSize,
        'created,desc',
        currentChuDe.value?.guid ?? '',
        trangThai,
        startDate.value != null
            ? startDate.value!.toUtc().toIso8601String()
            : '',
        endDate.value != null ? endDate.value!.toUtc().toIso8601String() : '',
      );
      if (pageIndex == 1) {
        listQuestion.value = response.data ?? [];
      } else {
        listQuestion.addAll(response.data ?? []);
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
