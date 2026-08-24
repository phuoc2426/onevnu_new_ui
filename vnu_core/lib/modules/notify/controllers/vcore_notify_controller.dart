import 'dart:async';

import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/data/api_response.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/browser/views/vcore_html_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_detail_view.dart';
import 'package:vnu_core/modules/question/views/vcore_question_detail_view.dart';
import 'package:vnu_core/modules/system_news/views/vcore_system_news_detail_view.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/screens/vcore_preview_pdf_screen.dart';

class VcoreNotifyController extends GetxController {
  BuildContext? context;

  NotifyStatus status = NotifyStatus.unRead;

  RefreshController refreshController = RefreshController();

  RxList<ThongBaoModel> listThongBao = RxList([]);

  int pageIndex = 1;
  int pageSize = 20;
  var isLoadMoreEnable = true;
  StreamSubscription<dynamic>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = Globals().unreadCountStream.stream.listen(
      (count) {
        if (status == NotifyStatus.unRead && count < listThongBao.length) {
          refreshData();
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    refreshController.dispose();
    super.dispose();
  }

  refreshData() {
    refreshController.refreshCompleted();
    pageIndex = 1;

    _loadData();
  }

  loadMoreData() {
    pageIndex += 1;
    _loadData();
  }

  _loadData() async {
    Utils.showProgress(context);
    try {
      ApiResponse<List<ThongBaoModel>> response;
      if (status == NotifyStatus.unRead) {
        response = await ApiRepository()
            .getThongBao(pageIndex, pageSize, 'created,desc', false);
      } else {
        response = await ApiRepository()
            .getAllThongBao(pageIndex, pageSize, 'created,desc');
      }
      if (pageIndex == 1) {
        listThongBao.value = response.data ?? [];
      } else {
        listThongBao.addAll(response.data ?? []);
      }

      refreshController.refreshCompleted();
      refreshController.loadComplete();
      Utils.dismissProgress(context);
    } catch (e) {
      AppFeedback.showError(e);
      refreshController.refreshCompleted();

      Utils.dismissProgress(context);
      refreshController.loadComplete();
    }
  }

  handleViewNofity(ThongBaoModel thongbao) async {
    String guidItem = thongbao.guidItem ?? '';
    String loaiNotification = thongbao.loaiNotification ?? '';

    if (guidItem.isEmpty || loaiNotification.isEmpty) {
      return;
    }

    if (loaiNotification == LoaiThongBao.CamNang.name) {
      SmartDialog.showLoading();
      try {
        final CamNangModel model =
            await ApiRepository().getDetailCamNang(guidItem);
        _markNotificationReadBestEffort(guidItem, loaiNotification);
        Get.to(
          () => VCorePreviewPdfScreen(
            title: model.tieuDe ?? '',
            fileId: model.guidFileCamNangs?.first ?? '',
          ),
        );
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        AppFeedback.showError(e);
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.TinTuc.name) {
      SmartDialog.showLoading();
      try {
        final TinTucModel response =
            await ApiRepository().getDetailTinTuc(guidItem);
        _markNotificationReadBestEffort(guidItem, loaiNotification);
        SmartDialog.dismiss();

        Get.to(() => VcoreNewsDetailView(tinTucModel: response));
      } catch (e) {
        SmartDialog.dismiss();
        AppFeedback.showError(e);
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.Cmsvnu_TinTuc.name) {
      SmartDialog.showLoading();
      try {
        final TopTinTucDetailModel response =
            await ApiRepository().getChiTietCmsTinTuc(
          guidItem,
          kImageCmsWidhtHeight,
          kImageCmsWidhtHeight,
        );
        _markNotificationReadBestEffort(guidItem, loaiNotification);
        SmartDialog.dismiss();

        Get.to(
          () => VcoreHtmlView(
            title: response.tieuDe ?? '',
            html: response.noiDung ?? '',
          ),
        );
      } catch (e) {
        SmartDialog.dismiss();
        logError(e.toString());
        AppFeedback.showError(e);
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.TinHeThong.name) {
      SmartDialog.showLoading();
      try {
        final TinHeThongModel response =
            await ApiRepository().getChiTietTinHeThong(guidItem);
        _markNotificationReadBestEffort(guidItem, loaiNotification);
        Get.to(() => VcoreSystemNewsDetailView(tinTucModel: response));
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        AppFeedback.showError(e);
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.CauHoi.name ||
        loaiNotification == LoaiThongBao.ChuDeCauHoi.name ||
        loaiNotification == LoaiThongBao.TraLoiCauHoi.name) {
      SmartDialog.showLoading();
      try {
        final HoiDapModel response =
            await ApiRepository().getDetailCauHoiDap(guidItem);
        _markNotificationReadBestEffort(guidItem, loaiNotification);
        Get.to(() => VcoreQuestionDetailView(question: response));
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        AppFeedback.showError(e);
        logError(e.toString());
      }
      return;
    }

    if (loaiNotification == LoaiThongBao.PhongTro.name) {
      SmartDialog.showLoading();
      try {
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        AppFeedback.showError(e);
        logError(e.toString());
      }
      return;
    }
    if (loaiNotification == LoaiThongBao.HuongDanSuDung.name) {
      try {
        await ApiRepository().setIsRead(guidItem, loaiNotification);
        Globals().fetchUnreadCount();
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        logError(e.toString());
      }

      if (guidItem.isEmpty) {
        snackBarWarning('Không tồn tại hướng dẫn sử dụng với guid.');
      } else {
        Get.to(
          () => VCorePreviewPdfScreen(
            title: thongbao.tieuDe,
            fileId: guidItem,
          ),
        );
      }

      return;
    }

    if (loaiNotification == LoaiThongBao.TraLoiPhanAnh.name) {
      try {
        await ApiRepository().setIsRead(guidItem, loaiNotification);
        Globals().fetchUnreadCount();
      } catch (e) {
        logError(e.toString());
      }

      if (guidItem.isEmpty) {
        snackBarWarning('Không tồn tại phản ánh hiện trường với guid.');
      } else {
        SmartDialog.showLoading();
        try {
          var phanAnhHienTruongModel = await ApiRepository().getPaht(guidItem);
          SmartDialog.dismiss();
          Get.to(() => VcorePahtDetailView(
              phanAnhHienTruongModel: phanAnhHienTruongModel,
              isChuaXuLy: false));
        } catch (e) {
          SmartDialog.dismiss();
          logError(e.toString());
          AppFeedback.showError(e);
        }
      }

      return;
    }

    if (loaiNotification == LoaiThongBao.ThuTucHanhChinh.name) {
      logWarning('Not hanlde notify, undefine notify type...');
      snackBarWarning('Chưa hỗ trợ định dạng thông báo.');
      return;
    }
  }
  void _markNotificationReadBestEffort(
    String guidItem,
    String loaiNotification,
  ) {
    unawaited(() async {
      try {
        await ApiRepository().setIsRead(guidItem, loaiNotification);
        await Globals().fetchUnreadCount();
      } catch (e) {
        logWarning(
          '[NOTIFICATION] mark-read failed type=$loaiNotification '
          'hasGuid=${guidItem.isNotEmpty} error=$e',
        );
      }
    }());
  }

}

