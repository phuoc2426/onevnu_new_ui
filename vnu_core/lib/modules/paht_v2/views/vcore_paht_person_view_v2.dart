import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/modules/paht_v2/controllers/vcore_paht_person_controller_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_detail_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_item_widget_v2.dart';
import 'package:vnu_core/modules/paht_v2/widgets/paht_v2_empty_state.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

class VcorePahtPersonViewV2 extends StatelessWidget {
  const VcorePahtPersonViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: const [
            _PahtPersonTabsV2(),
            Expanded(
              child: TabBarView(
                children: [
                  VcorePahtPersonListViewV2(trangThaiXuLy: 'ChuaTraLoi'),
                  VcorePahtPersonListViewV2(trangThaiXuLy: 'DaTraLoi'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PahtPersonTabsV2 extends StatelessWidget {
  const _PahtPersonTabsV2();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF3F6F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xff637392),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppTheme.colorMain,
          borderRadius: BorderRadius.circular(12),
        ),
        tabs: const [
          Tab(text: 'Chưa xử lý'),
          Tab(text: 'Đã xử lý'),
        ],
      ),
    );
  }
}

class VcorePahtPersonListViewV2 extends GetView<VcorePahtPersonControllerV2> {
  final String trangThaiXuLy;

  const VcorePahtPersonListViewV2({super.key, required this.trangThaiXuLy});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcorePahtPersonControllerV2>(
      init: VcorePahtPersonControllerV2(trangThaiXuLy),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listPaht.isEmpty && !controller.isLoading.value) {
              controller.refreshData();
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Obx(
              () => Column(
                children: [
                  Container(
                    height: 58,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: VcoreDropdown2SelectWidget(
                      items: controller.listChuDe.map((e) => VcoreDropdownModel(text: e.tenChuDe ?? '', guid: e.guid ?? '')).toList(),
                      hint: 'Chọn chủ đề',
                      selectedGuid: controller.currentChuDe.value?.guid,
                      onSelected: controller.changeChuDe,
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
                                        isChuaXuLy: trangThaiXuLy == 'ChuaTraLoi',
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
}
