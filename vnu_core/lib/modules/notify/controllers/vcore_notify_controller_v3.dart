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
import 'package:vnu_core/modules/notify/views/vcore_notify_detail_view_v3.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/screens/vcore_preview_pdf_screen.dart';

class VcoreNotifyControllerV3
    extends GetxController {
  VcoreNotifyControllerV3({
    this.systemOnly = false,
  });

  final bool systemOnly;

  BuildContext? context;

  final RefreshController
  systemRefreshController =
  RefreshController();

  final RefreshController
  trainingRefreshController =
  RefreshController();

  final RxList<ThongBaoModel>
  listSystemNews =
      <ThongBaoModel>[].obs;

  final RxList<ThongBaoDaoTaoModel>
  listTrainingNews =
      <ThongBaoDaoTaoModel>[].obs;

  final RxSet<String> readDaoTaoIds =
      <String>{}.obs;

  final RxInt systemUnreadCount =
      0.obs;

  final RxInt trainingUnreadCount =
      0.obs;

  final RxBool isLoadingSystemNews =
      false.obs;

  final RxBool
  isLoadingTrainingNews =
      false.obs;

  final RxBool
  canLoadMoreSystemNews =
      true.obs;

  final int pageSize = 20;

  int systemPageIndex = 1;

  StreamSubscription<dynamic>?
  _subscription;

  @override
  void onInit() {
    super.onInit();

    fetchSystemUnreadCount();

    _subscription = Globals()
        .unreadCountStream
        .stream
        .listen(
          (dynamic count) {
        final int? parsedCount =
        count is int
            ? count
            : int.tryParse(
          count.toString(),
        );

        if (parsedCount != null) {
          systemUnreadCount.value =
              parsedCount;
        }
      },
    );

    if (!systemOnly) {
      loadReadDaoTaoIds().then((_) {
        refreshTrainingNews();
      });
    }

    refreshSystemNews();
  }

  @override
  void onClose() {
    _subscription?.cancel();

    systemRefreshController.dispose();
    trainingRefreshController.dispose();

    super.onClose();
  }

  String get _readDaoTaoKey {
    final String username =
        Globals().usernameLogin;

    return 'read_daotao_notifications_'
        '$username';
  }

  String getThongBaoDaoTaoId(
      ThongBaoDaoTaoModel item,
      ) {
    return '${item.tieuDe ?? ''}_'
        '${item.noiDung?.hashCode ?? 0}';
  }

  Future<void>
  loadReadDaoTaoIds() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences
          .getInstance();

      final List<String> values =
          prefs.getStringList(
            _readDaoTaoKey,
          ) ??
              <String>[];

      readDaoTaoIds.value =
          values.toSet();

      _updateTrainingUnreadCount();
    } catch (error, stackTrace) {
      logError(
        'loadReadDaoTaoIds error: '
            '$error\n$stackTrace',
      );
    }
  }

  Future<void> markDaoTaoAsRead(
      ThongBaoDaoTaoModel item,
      ) async {
    final String id =
    getThongBaoDaoTaoId(item);

    if (readDaoTaoIds.contains(id)) {
      return;
    }

    readDaoTaoIds.add(id);

    try {
      final SharedPreferences prefs =
      await SharedPreferences
          .getInstance();

      await prefs.setStringList(
        _readDaoTaoKey,
        readDaoTaoIds.toList(),
      );
    } catch (error, stackTrace) {
      logError(
        'markDaoTaoAsRead error: '
            '$error\n$stackTrace',
      );
    }

    _updateTrainingUnreadCount();
    update();
  }

  bool isDaoTaoRead(
      ThongBaoDaoTaoModel item,
      ) {
    return readDaoTaoIds.contains(
      getThongBaoDaoTaoId(item),
    );
  }

  void _updateTrainingUnreadCount() {
    int unreadCount = 0;

    for (
    final ThongBaoDaoTaoModel item
    in listTrainingNews
    ) {
      if (!isDaoTaoRead(item)) {
        unreadCount++;
      }
    }

    trainingUnreadCount.value =
        unreadCount;
  }

  Future<void>
  fetchSystemUnreadCount() async {
    try {
      final int count =
      await ApiRepository()
          .getNotificationCount(
        isRead: false,
      );

      systemUnreadCount.value =
          count;
    } catch (error, stackTrace) {
      /*
       * Tân sinh viên có thể nhận FCM
       * nhưng backend NotificationReceiver
       * chưa hỗ trợ AdmittedStudent.
       */
      logError(
        'fetchSystemUnreadCount error: '
            '$error\n$stackTrace',
      );

      if (systemOnly) {
        systemUnreadCount.value = 0;
      }
    }
  }

  Future<void>
  refreshSystemNews() async {
    systemPageIndex = 1;
    canLoadMoreSystemNews.value =
    true;

    await _loadSystemNews(
      isRefresh: true,
    );

    if (systemRefreshController
        .isRefresh) {
      systemRefreshController
          .refreshCompleted();
    }
  }

  Future<void>
  loadMoreSystemNews() async {
    if (!canLoadMoreSystemNews.value ||
        isLoadingSystemNews.value) {
      systemRefreshController
          .loadNoData();
      return;
    }

    systemPageIndex++;

    await _loadSystemNews(
      isRefresh: false,
    );

    if (!canLoadMoreSystemNews.value) {
      systemRefreshController
          .loadNoData();
    } else {
      systemRefreshController
          .loadComplete();
    }
  }

  Future<void> _loadSystemNews({
    required bool isRefresh,
  }) async {
    if (isLoadingSystemNews.value) {
      return;
    }

    isLoadingSystemNews.value = true;

    try {
      final ApiResponse<
          List<ThongBaoModel>>
      response =
      await ApiRepository()
          .getAllThongBao(
        systemPageIndex,
        pageSize,
        'created,desc',
      );

      final List<ThongBaoModel>
      items =
          response.data ??
              <ThongBaoModel>[];

      if (isRefresh) {
        listSystemNews.assignAll(
          items,
        );
      } else {
        listSystemNews.addAll(
          items,
        );
      }

      canLoadMoreSystemNews.value =
          items.length >= pageSize;

      await fetchSystemUnreadCount();
    } catch (error, stackTrace) {
      logError(
        'loadSystemNews error: '
            '$error\n$stackTrace',
      );

      if (!systemOnly) {
        snackBarError(
          _extractErrorMessage(error),
        );
      }

      if (!isRefresh &&
          systemPageIndex > 1) {
        systemPageIndex--;
      }

      canLoadMoreSystemNews.value =
      false;
    } finally {
      isLoadingSystemNews.value =
      false;
    }
  }

  Future<void>
  refreshTrainingNews() async {
    if (systemOnly ||
        isLoadingTrainingNews.value) {
      return;
    }

    isLoadingTrainingNews.value =
    true;

    try {
      final List<ThongBaoDaoTaoModel>
      items =
      <ThongBaoDaoTaoModel>[];

      await _appendTrainingNews(
        items,
        'TruongChinh',
      );

      await _appendTrainingNews(
        items,
        'BangKep',
      );

      await _appendTrainingNews(
        items,
        'TruongGui',
      );

      listTrainingNews.assignAll(
        items.where(
              (
              ThongBaoDaoTaoModel item,
              ) {
            return item.tieuDe
                ?.trim()
                .isNotEmpty ==
                true;
          },
        ),
      );

      _updateTrainingUnreadCount();
    } catch (error, stackTrace) {
      logError(
        'refreshTrainingNews error: '
            '$error\n$stackTrace',
      );

      snackBarError(
        _extractErrorMessage(error),
      );
    } finally {
      isLoadingTrainingNews.value =
      false;

      if (trainingRefreshController
          .isRefresh) {
        trainingRefreshController
            .refreshCompleted();
      }
    }
  }

  Future<void> _appendTrainingNews(
      List<ThongBaoDaoTaoModel> target,
      String type,
      ) async {
    try {
      final ThongBaoDaoTaoModel item =
      await ApiRepository()
          .getThongBaoDaoTao(
        type,
      );

      target.add(item);
    } catch (error, stackTrace) {
      logError(
        'getThongBaoDaoTao '
            '$type error: '
            '$error\n$stackTrace',
      );
    }
  }

  Future<void> handleViewNotify(
      BuildContext pageContext,
      ThongBaoModel notification,
      ) async {
    final String guidItem =
        notification.guidItem?.trim() ??
            '';

    final String notificationType =
        notification.loaiNotification
            ?.trim() ??
            '';

    if (notification.isRead == false) {
      notification.isRead = true;
      listSystemNews.refresh();

      try {
        await ApiRepository().setIsRead(
          guidItem,
          notificationType,
        );

        await fetchSystemUnreadCount();

        Globals().fetchUnreadCount();
      } catch (error, stackTrace) {
        logError(
          'setIsRead error: '
              '$error\n$stackTrace',
        );
      }
    }

    try {
      if (notificationType ==
          LoaiThongBao
              .TinHeThong
              .name) {
        await _openSystemDetail(
          notification,
          guidItem,
        );

        return;
      }

      if (notificationType ==
          LoaiThongBao.CamNang.name) {
        if (guidItem.isEmpty) {
          snackBarWarning(
            'Thông báo không có '
                'tệp cẩm nang.',
          );
          return;
        }

        Get.to(
              () =>
              VCorePreviewPdfScreen(
                title:
                notification.tieuDe ??
                    'Cẩm nang',
                fileId: guidItem,
              ),
        );

        return;
      }

      if (notificationType ==
          LoaiThongBao.TinTuc.name) {
        if (guidItem.isEmpty) {
          _openFallbackDetail(notification, 'Tin tức');
          return;
        }

        final TinTucModel detail =
        await ApiRepository()
            .getDetailTinTuc(
          guidItem,
        );

        Get.to(
              () =>
              VcoreNotifyDetailViewV3(
                title: detail.tieuDe ??
                    notification.tieuDe ??
                    'Tin tức',
                htmlContent:
                detail.htmlNoiDungTinBai ??
                    notification.noiDung ??
                    '',
                sender:
                detail.donViXuatBan ??
                    notification
                        .tenNguoiGui ??
                    'Cổng thông tin VNU',
                date:
                detail.thoiGianTao ??
                    notification.ngayGui,
                category: 'Tin tức',
                fileGuids:
                detail.guidFileDinhKems,
                fileNames:
                detail.tenFileDinhKem ==
                    null
                    ? null
                    : <String>[
                  detail
                      .tenFileDinhKem!,
                ],
                showMetadata: true,
              ),
        );

        return;
      }

      if (notificationType ==
          LoaiThongBao
              .Cmsvnu_TinTuc
              .name) {
        if (guidItem.isEmpty) {
          _openFallbackDetail(notification, 'Tin tức VNU');
          return;
        }

        final TopTinTucDetailModel
        detail =
        await ApiRepository()
            .getChiTietCmsTinTuc(
          guidItem,
          kImageCmsWidhtHeight,
          kImageCmsWidhtHeight,
        );

        Get.to(
              () =>
              VcoreNotifyDetailViewV3(
                title: detail.tieuDe ??
                    notification.tieuDe ??
                    'Tin tức',
                htmlContent:
                detail.noiDung ??
                    notification.noiDung ??
                    '',
                sender:
                notification.tenNguoiGui ??
                    'Cổng thông tin VNU',
                date:
                notification.ngayGui,
                category: 'Tin tức VNU',
              ),
        );

        return;
      }

      if (notificationType ==
          LoaiThongBao
              .HuongDanSuDung
              .name) {
        if (guidItem.isEmpty) {
          snackBarWarning(
            'Không tồn tại hướng dẫn '
                'sử dụng với guid.',
          );
          return;
        }

        Get.to(
              () =>
              VCorePreviewPdfScreen(
                title:
                notification.tieuDe,
                fileId: guidItem,
              ),
        );

        return;
      }

      _openFallbackDetail(
        notification,
        notificationType,
      );
    } catch (error, stackTrace) {
      logError(
        'handleViewNotify error: '
            '$error\n$stackTrace',
      );

      _openFallbackDetail(
        notification,
        notificationType,
      );
    }
  }

  Future<void> _openSystemDetail(
      ThongBaoModel notification,
      String guidItem,
      ) async {
    if (guidItem.isEmpty) {
      _openFallbackDetail(
        notification,
        LoaiThongBao
            .TinHeThong
            .name,
      );
      return;
    }

    try {
      final TinHeThongModel detail =
      await ApiRepository()
          .getChiTietTinHeThong(
        guidItem,
      );

      Get.to(
            () =>
            VcoreNotifyDetailViewV3(
              title: detail.tieuDe ??
                  notification.tieuDe ??
                  'Thông báo',
              htmlContent:
              detail.noiDung ??
                  notification.noiDung ??
                  '',
              sender:
              detail.nguonTin ??
                  notification
                      .tenNguoiGui ??
                  'Hệ thống',
              date:
              detail.thoiGian ??
                  notification.ngayGui,
              category:
              'Tin hệ thống',
              fileGuids:
              detail.guidFileDinhKems,
              fileNames:
              detail.tenFileDinhKems,
            ),
      );
    } catch (error, stackTrace) {
      logError(
        'getChiTietTinHeThong error: '
            '$error\n$stackTrace',
      );

      _openFallbackDetail(
        notification,
        'Tin hệ thống',
      );
    }
  }

  void _openFallbackDetail(
      ThongBaoModel notification,
      String notificationType,
      ) {
    Get.to(
          () => VcoreNotifyDetailViewV3(
        title:
        notification.tieuDe ??
            'Thông báo',
        htmlContent:
        notification.noiDung ?? '',
        sender:
        notification.tenNguoiGui ??
            'Hệ thống',
        date:
        notification.ngayGui,
        category:
        notificationType.isNotEmpty
            ? notificationType
            : 'Hệ thống',
      ),
    );
  }

  String _extractErrorMessage(
      dynamic error,
      ) {
    if (error == null) {
      return 'Không thể tải thông báo.';
    }

    final String message =
    error.toString().trim();

    if (message.isEmpty) {
      return 'Không thể tải thông báo.';
    }

    return message.replaceFirst(
      'Exception: ',
      '',
    );
  }
}
