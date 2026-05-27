import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/khu_vuc_ban_do_model.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/modules/paht/controllers/vcore_paht_comunitation_controller.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_detail_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_item_widget.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

class VcorePahtComunitationView
    extends GetView<VcorePahtComunitationController> {
  const VcorePahtComunitationView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcorePahtComunitationController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: ProgressHubWidget(
            contextComplete: (hubContext) {
              controller.context = hubContext;
              if (controller.listPaht.isEmpty) {
                controller.refreshData();
              }
            },
            child: Obx(
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

                  Container(
                    height: 58,
                    // color: Colors.white,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Center(
                      child: VcoreDropdown2SelectWidget(
                        items: controller.listChuDe
                            .map((e) => VcoreDropdownModel(
                                text: e.tenChuDe ?? '', guid: e.guid ?? ''))
                            .toList(),
                        hint: 'Chọn chủ đề',
                        selectedGuid: controller.currentChuDe.value?.guid,
                        onSelected: (value) {
                          controller.changeChuDe(value);
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: controller.listPaht.isNotEmpty
                        ? SmartRefresher(
                            controller: controller.refreshController,
                            enablePullUp: true,
                            onRefresh: controller.refreshData,
                            onLoading: controller.loadMoreData,
                            header: const WaterDropHeader(),
                            footer: const RefreshFooterWidget(),
                            child: ListView.separated(
                                itemBuilder: (ctx, index) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      Get.to(() => VcorePahtDetailView(
                                            phanAnhHienTruongModel:
                                                controller.listPaht[index],
                                            isChuaXuLy: false,
                                          ));
                                    },
                                    child: VcorePahtItemWidget(
                                      phanAnhHienTruongModel:
                                          controller.listPaht[index],
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) => spaceHeight(12),
                                itemCount: controller.listPaht.length),
                          )
                        : Center(
                            child: Text(
                              "Không có dữ liệu",
                              style: TextStyles.regular,
                            ),
                          ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
