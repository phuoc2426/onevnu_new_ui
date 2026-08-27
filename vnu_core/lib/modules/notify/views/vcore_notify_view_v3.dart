import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/guide/guide.dart';
import 'package:vnu_core/modules/notify/controllers/vcore_notify_controller_v3.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_detail_view_v3.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_item_widget_v3.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreNotifyViewV3
    extends StatefulWidget {
  const VcoreNotifyViewV3({
    super.key,
    this.systemOnly = false,
  });

  final bool systemOnly;

  @override
  State<VcoreNotifyViewV3> createState() =>
      _VcoreNotifyViewV3State();
}

class _VcoreNotifyViewV3State
    extends State<VcoreNotifyViewV3>
    with SingleTickerProviderStateMixin {
  late final TabController
  _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length:
      widget.systemOnly ? 1 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String controllerTag =
    widget.systemOnly
        ? 'notify-system-only'
        : 'notify-full';

    return GetBuilder<
        VcoreNotifyControllerV3>(
      init: VcoreNotifyControllerV3(
        systemOnly:
        widget.systemOnly,
      ),
      tag: controllerTag,
      global: false,
      builder: (
          VcoreNotifyControllerV3
          controller,
          ) {
        controller.context = context;

        return AppGuideAnchor(
          id: 'notify.page',
          child: VcoreModuleScaffold(
          title: widget.systemOnly
              ? 'Thông báo hệ thống'
              : 'Thông báo',
          showBackButton: true,
          body: widget.systemOnly
              ? AppGuideAnchor(
                  id: 'notify.list',
                  child: _buildSystemNewsList(controller),
                )
              : Column(
            children: <Widget>[
              AppGuideAnchor(
                id: 'notify.tabs',
                child: _buildTabBar(
                  controller,
                ),
              ),
              Expanded(
                child: AppGuideAnchor(
                  id: 'notify.list',
                  child: TabBarView(
                  controller:
                  _tabController,
                  children:
                  <Widget>[
                    _buildSystemNewsList(
                      controller,
                    ),
                    _buildTrainingNewsList(
                      controller,
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar(
      VcoreNotifyControllerV3 controller,
      ) {
    return Container(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      height: 48,
      decoration: BoxDecoration(
        color:
        const Color(0xFFF0F4FA),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Obx(
            () {
          final int systemCount =
              controller
                  .systemUnreadCount
                  .value;

          final int trainingCount =
              controller
                  .trainingUnreadCount
                  .value;

          final String systemLabel =
          systemCount > 0
              ? 'Tin hệ thống '
              '($systemCount)'
              : 'Tin hệ thống';

          final String trainingLabel =
          trainingCount > 0
              ? 'Tin đào tạo '
              '($trainingCount)'
              : 'Tin đào tạo';

          return TabBar(
            controller:
            _tabController,
            indicator: BoxDecoration(
              color:
              const Color(
                0xFF003392,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            indicatorSize:
            TabBarIndicatorSize.tab,
            indicatorPadding:
            const EdgeInsets.all(3),
            labelColor: Colors.white,
            unselectedLabelColor:
            const Color(0xFF637392),
            labelStyle:
            TextStyles.semiBold
                .copyWith(
              fontSize:
              AppFontSizes
                  .mediumSmall,
            ),
            unselectedLabelStyle:
            TextStyles.regular
                .copyWith(
              fontSize:
              AppFontSizes
                  .mediumSmall,
            ),
            dividerColor:
            Colors.transparent,
            tabs: <Widget>[
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(systemLabel),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(trainingLabel),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemNewsList(
      VcoreNotifyControllerV3 controller,
      ) {
    return Obx(
          () {
        if (controller
            .isLoadingSystemNews
            .value) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        if (controller
            .listSystemNews
            .isEmpty) {
          return _buildEmptyState(
            'Chưa có thông báo hệ thống',
          );
        }

        return SmartRefresher(
          controller: controller
              .systemRefreshController,
          enablePullDown: true,
          enablePullUp:
          controller
              .canLoadMoreSystemNews
              .value,
          onRefresh:
          controller
              .refreshSystemNews,
          onLoading:
          controller
              .loadMoreSystemNews,
          header:
          const WaterDropHeader(),
          footer:
          const RefreshFooterWidget(),
          child: ListView.builder(
            padding:
            const EdgeInsets.only(
              bottom: 24,
            ),
            itemCount: controller
                .listSystemNews
                .length,
            itemBuilder: (
                BuildContext context,
                int index,
                ) {
              final item = controller
                  .listSystemNews[index];

              return VcoreNotifyItemWidgetV3(
                thongBaoModel: item,
                isRead:
                item.isRead ?? true,
                onTap: () {
                  controller
                      .handleViewNotify(
                    context,
                    item,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrainingNewsList(
      VcoreNotifyControllerV3 controller,
      ) {
    return Obx(
          () {
        if (controller
            .isLoadingTrainingNews
            .value) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        if (controller
            .listTrainingNews
            .isEmpty) {
          return _buildEmptyState(
            'Chưa có thông báo đào tạo',
          );
        }

        return SmartRefresher(
          controller: controller
              .trainingRefreshController,
          enablePullDown: true,
          enablePullUp: false,
          onRefresh:
          controller
              .refreshTrainingNews,
          header:
          const WaterDropHeader(),
          child: ListView.builder(
            padding:
            const EdgeInsets.only(
              bottom: 24,
            ),
            itemCount: controller
                .listTrainingNews
                .length,
            itemBuilder: (
                BuildContext context,
                int index,
                ) {
              final item = controller
                  .listTrainingNews[index];

              final bool isRead =
              controller
                  .isDaoTaoRead(
                item,
              );

              return VcoreNotifyItemWidgetV3(
                daoTaoModel: item,
                isRead: isRead,
                onTap: () async {
                  await controller
                      .markDaoTaoAsRead(
                    item,
                  );

                  Get.to(
                        () =>
                        VcoreNotifyDetailViewV3(
                          title:
                          item.tieuDe ??
                              'Thông báo '
                                  'đào tạo',
                          htmlContent:
                          item.noiDung ??
                              '',
                          sender:
                          'Phòng Đào tạo',
                          // API đào tạo hiện không trả ngày; không tự gán
                          // thời điểm mở màn hình vì sẽ hiển thị sai dữ liệu.
                          date: null,
                          category:
                          'Tin đào tạo',
                        ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      String message,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons
                .notifications_off_outlined,
            size: 48,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
            TextStyles.regular.copyWith(
              color:
              const Color(
                0xFF879ABF,
              ),
              fontSize:
              AppFontSizes.medium,
            ),
          ),
        ],
      ),
    );
  }
}
