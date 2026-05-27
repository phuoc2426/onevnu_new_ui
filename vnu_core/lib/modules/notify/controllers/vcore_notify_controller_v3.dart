import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/data/api_response.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/browser/views/vcore_html_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_detail_view_v3.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_detail_view.dart';
import 'package:vnu_core/modules/question/views/vcore_question_detail_view.dart';
import 'package:vnu_core/modules/system_news/views/vcore_system_news_detail_view.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/screens/vcore_preview_pdf_screen.dart';

class VcoreNotifyControllerV3 extends GetxController {
  BuildContext? context;

  // Refresher controllers for both tabs
  final RefreshController systemRefreshController = RefreshController();
  final RefreshController trainingRefreshController = RefreshController();

  // Tab 1: System notifications
  RxList<ThongBaoModel> listSystemNews = RxList([]);
  int systemPageIndex = 1;
  final int pageSize = 20;
  RxInt systemUnreadCount = 0.obs;

  // Tab 2: Training notifications
  RxList<ThongBaoDaoTaoModel> listTrainingNews = RxList([]);
  RxSet<String> readDaoTaoIds = RxSet<String>({});
  RxInt trainingUnreadCount = 0.obs;

  StreamSubscription<dynamic>? _subscription;

  @override
  void onInit() {
    super.onInit();
    // Fetch unread counts and data
    fetchSystemUnreadCount();
    _subscription = Globals().unreadCountStream.stream.listen((count) {
      systemUnreadCount.value = count;
    });
    
    // Load local storage read ids for training news
    loadReadDaoTaoIds().then((_) {
      refreshTrainingNews();
    });
    
    refreshSystemNews();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    systemRefreshController.dispose();
    trainingRefreshController.dispose();
    super.onClose();
  }

  // --- Read/Write SharedPreferences for Training Notifications ---
  String get _readDaoTaoKey {
    final username = Globals().usernameLogin;
    return "read_daotao_notifications_$username";
  }

  String getThongBaoDaoTaoId(ThongBaoDaoTaoModel item) {
    return "${item.tieuDe ?? ''}_${item.noiDung?.hashCode ?? 0}";
  }

  Future<void> loadReadDaoTaoIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_readDaoTaoKey) ?? [];
      readDaoTaoIds.value = list.toSet();
      _updateTrainingUnreadCount();
    } catch (e) {
      logError("loadReadDaoTaoIds error: $e");
    }
  }

  Future<void> markDaoTaoAsRead(ThongBaoDaoTaoModel item) async {
    final id = getThongBaoDaoTaoId(item);
    if (!readDaoTaoIds.contains(id)) {
      readDaoTaoIds.add(id);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_readDaoTaoKey, readDaoTaoIds.toList());
      } catch (e) {
        logError("markDaoTaoAsRead error: $e");
      }
      _updateTrainingUnreadCount();
      update();
    }
  }

  bool isDaoTaoRead(ThongBaoDaoTaoModel item) {
    final id = getThongBaoDaoTaoId(item);
    return readDaoTaoIds.contains(id);
  }

  void _updateTrainingUnreadCount() {
    int unread = 0;
    for (var item in listTrainingNews) {
      if (!isDaoTaoRead(item)) {
        unread++;
      }
    }
    trainingUnreadCount.value = unread;
  }

  // --- Fetch System Notifications (Tab 1) ---
  Future<void> fetchSystemUnreadCount() async {
    try {
      final count = await ApiRepository().getNotificationCount(isRead: false);
      systemUnreadCount.value = count;
    } catch (e) {
      logError("fetchSystemUnreadCount error: $e");
    }
  }

  Future<void> refreshSystemNews() async {
    systemPageIndex = 1;
    await _loadSystemNews();
    systemRefreshController.refreshCompleted();
  }

  Future<void> loadMoreSystemNews() async {
    systemPageIndex += 1;
    await _loadSystemNews();
    systemRefreshController.loadComplete();
  }

  Future<void> _loadSystemNews() async {
    Utils.showProgress(context);
    try {
      ApiResponse<List<ThongBaoModel>> response = await ApiRepository()
          .getAllThongBao(systemPageIndex, pageSize, 'created,desc');
      
      if (systemPageIndex == 1) {
        listSystemNews.value = response.data ?? [];
      } else {
        listSystemNews.addAll(response.data ?? []);
      }
      fetchSystemUnreadCount();
      Utils.dismissProgress(context);
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
    }
  }

  // --- Fetch Training Notifications (Tab 2) ---
  Future<void> refreshTrainingNews() async {
    Utils.showProgress(context);
    try {
      List<ThongBaoDaoTaoModel> listObj = [];
      try {
        var response = await ApiRepository().getThongBaoDaoTao('TruongChinh');
        listObj.add(response);
      } catch (e) {
        logError("getThongBaoDaoTao TruongChinh error: $e");
      }

      try {
        var response = await ApiRepository().getThongBaoDaoTao('BangKep');
        listObj.add(response);
      } catch (e) {
        logError("getThongBaoDaoTao BangKep error: $e");
      }

      try {
        var response = await ApiRepository().getThongBaoDaoTao('TruongGui');
        listObj.add(response);
      } catch (e) {
        logError("getThongBaoDaoTao TruongGui error: $e");
      }

      // Filter out items without titles
      listTrainingNews.value = listObj.where((e) => e.tieuDe?.isNotEmpty == true).toList();
      _updateTrainingUnreadCount();
      trainingRefreshController.refreshCompleted();
      Utils.dismissProgress(context);
    } catch (e) {
      snackBarError(e.toString());
      trainingRefreshController.refreshCompleted();
      Utils.dismissProgress(context);
    }
  }

  // --- Route & Mark Read system notification ---
  Future<void> handleViewNotify(BuildContext context, ThongBaoModel thongbao) async {
    String guidItem = thongbao.guidItem ?? '';
    String loaiNotification = thongbao.loaiNotification ?? '';

    // Mark as read first
    if (thongbao.isRead == false) {
      thongbao.isRead = true;
      listSystemNews.refresh();
      try {
        await ApiRepository().setIsRead(guidItem, loaiNotification);
        Globals().fetchUnreadCount();
        fetchSystemUnreadCount();
      } catch (e) {
        logError("setIsRead error: $e");
      }
    }

    Utils.showProgress(context);
    try {
      if (loaiNotification == LoaiThongBao.TinHeThong.name) {
        final TinHeThongModel detail = await ApiRepository().getChiTietTinHeThong(guidItem);
        Utils.dismissProgress(context);
        Get.to(() => VcoreNotifyDetailViewV3(
          title: detail.tieuDe ?? thongbao.tieuDe ?? 'Thông báo',
          htmlContent: detail.noiDung ?? thongbao.noiDung ?? '',
          sender: detail.nguonTin ?? thongbao.tenNguoiGui ?? 'Hệ thống',
          date: detail.thoiGian ?? thongbao.ngayGui ?? DateTime.now(),
          category: 'Tin hệ thống',
          fileGuids: detail.guidFileDinhKems,
          fileNames: detail.tenFileDinhKems,
        ));
        return;
      }

      if (loaiNotification == LoaiThongBao.CamNang.name) {
        final CamNangModel detail = await ApiRepository().getDetailCamNang(guidItem);
        Utils.dismissProgress(context);
        Get.to(
          () => VCorePreviewPdfScreen(
            title: detail.tieuDe ?? thongbao.tieuDe ?? '',
            fileId: detail.guidFileCamNangs?.first ?? '',
          ),
        );
        return;
      }

      if (loaiNotification == LoaiThongBao.TinTuc.name) {
        final TinTucModel detail = await ApiRepository().getDetailTinTuc(guidItem);
        Utils.dismissProgress(context);
        Get.to(() => VcoreNotifyDetailViewV3(
          title: detail.tieuDe ?? thongbao.tieuDe ?? 'Tin tức',
          htmlContent: detail.htmlNoiDungTinBai ?? thongbao.noiDung ?? '',
          sender: detail.donViXuatBan ?? thongbao.tenNguoiGui ?? 'Cổng thông tin VNU',
          date: detail.thoiGianTao ?? thongbao.ngayGui ?? DateTime.now(),
          category: 'Tin tức',
          fileGuids: detail.guidFileDinhKems,
          fileNames: detail.tenFileDinhKem != null ? [detail.tenFileDinhKem!] : null,
          showMetadata: true,
        ));
        return;
      }

      if (loaiNotification == LoaiThongBao.Cmsvnu_TinTuc.name) {
        final TopTinTucDetailModel detail = await ApiRepository().getChiTietCmsTinTuc(
            guidItem, kImageCmsWidhtHeight, kImageCmsWidhtHeight);
        Utils.dismissProgress(context);
        Get.to(() => VcoreNotifyDetailViewV3(
          title: detail.tieuDe ?? thongbao.tieuDe ?? 'Tin tức',
          htmlContent: detail.noiDung ?? thongbao.noiDung ?? '',
          sender: thongbao.tenNguoiGui ?? 'Cổng thông tin VNU',
          date: thongbao.ngayGui ?? DateTime.now(),
          category: 'Tin tức VNU',
        ));
        return;
      }

      if (loaiNotification == LoaiThongBao.HuongDanSuDung.name) {
        Utils.dismissProgress(context);
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

      // Default fallback detail screen for other notifications
      Utils.dismissProgress(context);
      Get.to(() => VcoreNotifyDetailViewV3(
        title: thongbao.tieuDe ?? 'Thông báo',
        htmlContent: thongbao.noiDung ?? '',
        sender: thongbao.tenNguoiGui ?? 'Hệ thống',
        date: thongbao.ngayGui ?? DateTime.now(),
        category: loaiNotification.isNotEmpty ? loaiNotification : 'Hệ thống',
      ));
    } catch (e) {
      Utils.dismissProgress(context);
      logError("handleViewNotify error, falling back to direct info: $e");
      Get.to(() => VcoreNotifyDetailViewV3(
        title: thongbao.tieuDe ?? 'Thông báo',
        htmlContent: thongbao.noiDung ?? '',
        sender: thongbao.tenNguoiGui ?? 'Hệ thống',
        date: thongbao.ngayGui ?? DateTime.now(),
        category: loaiNotification.isNotEmpty ? loaiNotification : 'Hệ thống',
      ));
    }
  }
}
