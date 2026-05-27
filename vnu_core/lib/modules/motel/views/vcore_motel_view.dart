import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/motel/views/vcore_model_item_widget.dart';
import 'package:vnu_core/modules/motel/views/vcore_motel_detail_view.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import '../controllers/vcore_motel_controller.dart';

class VcoreMotelView extends GetView<VcoreMotelController> {
  const VcoreMotelView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreMotelController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listPhongTro.isEmpty) {
              controller.refreshData();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Danh sách nhà trọ',
            body: Obx(
              () => Column(
                children: [
                  // Tab
                  Container(
                    height: 64,
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.listKhuVuc.length,
                      itemBuilder: (ctx, index) {
                        KhuVucBanDoModel khuVuc = controller.listKhuVuc[index];
                        bool isSelected =
                            khuVuc.guid == controller.currentKhuVuc.value?.guid;
                        return InkWell(
                          onTap: () {
                            controller.changeKhuVuc(khuVuc);
                          },
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.bgChildColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Text(
                                khuVuc.tenKhuVucBanDo ?? '',
                                style: TextStyles.regular.copyWith(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xff637392),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  spaceHeight(15),
                  // List
                  Expanded(
                    child: SmartRefresher(
                      controller: controller.refreshController,
                      enablePullUp: true,
                      onRefresh: controller.refreshData,
                      onLoading: controller.loadMoreData,
                      header: const WaterDropHeader(),
                      footer: const RefreshFooterWidget(),
                      child: ListView.separated(
                        separatorBuilder: (context, index) => spaceHeight(8),
                        itemCount: controller.listPhongTro.length,
                        itemBuilder: (ctx, index) {
                          PhongTroModel phongTroModel =
                              controller.listPhongTro[index];
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Get.to(
                                () => VcoreMotelDetailView(
                                  phongTroModel: phongTroModel,
                                ),
                              );
                            },
                            child: VcoreMotelItemWidget(
                              phongTroModel: phongTroModel,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
