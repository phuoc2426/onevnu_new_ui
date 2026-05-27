import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_item_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import '../controllers/vcore_notify_controller.dart';

class VcoreNotifyListView extends GetView<VcoreNotifyController> {
  final NotifyStatus status;
  const VcoreNotifyListView({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: VcoreNotifyController(),
        tag: const Uuid().v4(),
        builder: (controller) {
          controller.status = status;
          if (controller.listThongBao.isEmpty) {
            controller.refreshData();
          }

          return ProgressHubWidget(
            contextComplete: (hubContext) {
              controller.context = hubContext;
            },
            child: Obx(
              () => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: SmartRefresher(
                        controller: controller.refreshController,
                        enablePullUp: true,
                        onRefresh: controller.refreshData,
                        onLoading: controller.loadMoreData,
                        header: const WaterDropHeader(),
                        footer: const RefreshFooterWidget(),
                        child: ListView.separated(
                            padding: EdgeInsets.only(
                              bottom: floatingNavBottomPadding(context),
                            ),
                            itemBuilder: (ctx, index) {
                              ThongBaoModel thongBaoModel =
                                  controller.listThongBao[index];
                              return InkWell(
                                onTap: () {
                                  controller.handleViewNofity(thongBaoModel);
                                },
                                child: VcoreNotifyItemWidget(
                                  thongBaoModel: thongBaoModel,
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => spaceHeight(10),
                            itemCount: controller.listThongBao.length),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
