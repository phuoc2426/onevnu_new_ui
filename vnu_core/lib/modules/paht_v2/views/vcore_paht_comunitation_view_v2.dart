import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/models/khu_vuc_ban_do_model.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/modules/paht_v2/controllers/vcore_paht_comunitation_controller_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_detail_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_item_widget_v2.dart';
import 'package:vnu_core/modules/paht_v2/widgets/paht_v2_empty_state.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

class VcorePahtComunitationViewV2 extends GetView<VcorePahtComunitationControllerV2> {
  const VcorePahtComunitationViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcorePahtComunitationControllerV2>(
      init: VcorePahtComunitationControllerV2(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: ProgressHubWidget(
            contextComplete: (hubContext) {
              controller.context = hubContext;
              if (controller.listPaht.isEmpty && !controller.isLoading.value) {
                controller.refreshData();
              }
            },
            child: Obx(
              () => Column(
                children: [
                  _buildKhuVucFilter(controller),
                  _buildChuDeFilter(controller),
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
                              padding: const EdgeInsets.only(top: 4, bottom: 16),
                              itemCount: controller.listPaht.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, index) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final result = await Get.to(
                                      () => VcorePahtDetailViewV2(
                                        phanAnhHienTruongModel: controller.listPaht[index],
                                        isChuaXuLy: false,
                                      ),
                                    );
                                    if (result == true) {
                                      controller.refreshData();
                                    }
                                  },
                                  child: VcorePahtItemWidgetV2(phanAnhHienTruongModel: controller.listPaht[index]),
                                );
                              },
                            ),
                          )
                        : PahtV2EmptyState(
                            description: controller.isLoading.value ? 'Đang tải dữ liệu...' : 'Chưa có phản ánh phù hợp với bộ lọc hiện tại.',
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

  Widget _buildKhuVucFilter(VcorePahtComunitationControllerV2 controller) {
    return Container(
      height: 64,
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.listKhuVuc.length,
        itemBuilder: (ctx, index) {
          final KhuVucBanDoModel khuVuc = controller.listKhuVuc[index];
          final bool isSelected = khuVuc.guid == controller.currentKhuVuc.value?.guid;
          return InkWell(
            onTap: () => controller.changeKhuVuc(khuVuc),
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.colorMain : const Color(0xffF3F6F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  khuVuc.tenKhuVucBanDo ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xff637392),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChuDeFilter(VcorePahtComunitationControllerV2 controller) {
    return Container(
      height: 58,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: VcoreDropdown2SelectWidget(
        items: controller.listChuDe.map((e) => VcoreDropdownModel(text: e.tenChuDe ?? '', guid: e.guid ?? '')).toList(),
        hint: 'Chọn chủ đề',
        selectedGuid: controller.currentChuDe.value?.guid,
        onSelected: controller.changeChuDe,
      ),
    );
  }
}
