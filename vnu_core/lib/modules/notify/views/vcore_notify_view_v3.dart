import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_detail_view_v3.dart';
import '../controllers/vcore_notify_controller_v3.dart';
import 'vcore_notify_item_widget_v3.dart';

class VcoreNotifyViewV3 extends StatefulWidget {
  const VcoreNotifyViewV3({super.key});

  @override
  State<VcoreNotifyViewV3> createState() => _VcoreNotifyViewV3State();
}

class _VcoreNotifyViewV3State extends State<VcoreNotifyViewV3>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreNotifyControllerV3>(
      init: VcoreNotifyControllerV3(),
      builder: (controller) {
        controller.context = context;
        return VcoreModuleScaffold(
          title: 'Thông báo',
          showBackButton: true,
          body: Column(
            children: [
              // Custom Capsule Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xffF0F4FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() {
                  final sysCount = controller.systemUnreadCount.value;
                  final trainCount = controller.trainingUnreadCount.value;

                  final sysTabLabel = sysCount > 0 ? 'Tin hệ thống ($sysCount)' : 'Tin hệ thống';
                  final trainTabLabel = trainCount > 0 ? 'Tin đào tạo ($trainCount)' : 'Tin đào tạo';

                  return TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xff003392),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(3),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xff637392),
                    labelStyle: TextStyles.semiBold.copyWith(fontSize: 13),
                    unselectedLabelStyle: TextStyles.regular.copyWith(fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: sysTabLabel),
                      Tab(text: trainTabLabel),
                    ],
                  );
                }),
              ),
              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSystemNewsList(controller),
                    _buildTrainingNewsList(controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemNewsList(VcoreNotifyControllerV3 controller) {
    return Obx(() {
      if (controller.listSystemNews.isEmpty) {
        return _buildEmptyState('Chưa có thông báo hệ thống');
      }
      return SmartRefresher(
        controller: controller.systemRefreshController,
        enablePullDown: true,
        enablePullUp: true,
        onRefresh: controller.refreshSystemNews,
        onLoading: controller.loadMoreSystemNews,
        header: const WaterDropHeader(),
        footer: const RefreshFooterWidget(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: controller.listSystemNews.length,
          itemBuilder: (context, index) {
            final item = controller.listSystemNews[index];
            return VcoreNotifyItemWidgetV3(
              thongBaoModel: item,
              isRead: item.isRead ?? true,
              onTap: () {
                controller.handleViewNotify(context, item);
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildTrainingNewsList(VcoreNotifyControllerV3 controller) {
    return Obx(() {
      if (controller.listTrainingNews.isEmpty) {
        return _buildEmptyState('Chưa có thông báo đào tạo');
      }
      return SmartRefresher(
        controller: controller.trainingRefreshController,
        enablePullDown: true,
        enablePullUp: false,
        onRefresh: controller.refreshTrainingNews,
        header: const WaterDropHeader(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: controller.listTrainingNews.length,
          itemBuilder: (context, index) {
            final item = controller.listTrainingNews[index];
            final isRead = controller.isDaoTaoRead(item);
            return VcoreNotifyItemWidgetV3(
              daoTaoModel: item,
              isRead: isRead,
              onTap: () {
                controller.markDaoTaoAsRead(item);
                Get.to(
                  () => VcoreNotifyDetailViewV3(
                    title: item.tieuDe ?? 'Thông báo đào tạo',
                    htmlContent: item.noiDung ?? '',
                    sender: 'Phòng Đào tạo',
                    date: DateTime.now(),
                    category: 'Tin đào tạo',
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyles.regular.copyWith(
              color: const Color(0xff879ABF),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
