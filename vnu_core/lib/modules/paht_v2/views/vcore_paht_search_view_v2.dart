import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/paht_v2/controllers/vcore_paht_search_controller_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_detail_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_item_widget_v2.dart';
import 'package:vnu_core/modules/paht_v2/widgets/paht_v2_empty_state.dart';
// import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

class VcorePahtSearchViewV2 extends GetView<VcorePahtSearchControllerV2> {
  const VcorePahtSearchViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcorePahtSearchControllerV2>(
      init: VcorePahtSearchControllerV2(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: VcoreModuleScaffold(
            title: 'Tìm kiếm phản ánh',
            body: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffE4EAF2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.textEditingController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập nội dung tìm kiếm',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (value) {
                            Utils.hideKeyboard();
                            controller.refreshData();
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Utils.hideKeyboard();
                          controller.refreshData();
                        },
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => controller.listPaht.isNotEmpty
                        ? SmartRefresher(
                            controller: controller.refreshController,
                            enablePullUp: true,
                            onRefresh: controller.refreshData,
                            onLoading: controller.loadMoreData,
                            header: const WaterDropHeader(),
                            footer: const RefreshFooterWidget(),
                            child: ListView.separated(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 16,
                              ),
                              itemCount: controller.listPaht.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, index) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final result = await Get.to(
                                      () => VcorePahtDetailViewV2(
                                        phanAnhHienTruongModel:
                                            controller.listPaht[index],
                                        isChuaXuLy: false,
                                      ),
                                    );
                                    if (result == true) {
                                      controller.refreshData();
                                    }
                                  },
                                  child: VcorePahtItemWidgetV2(
                                    phanAnhHienTruongModel:
                                        controller.listPaht[index],
                                  ),
                                );
                              },
                            ),
                          )
                        : PahtV2EmptyState(
                            description: controller.isLoading.value
                                ? 'Đang tìm kiếm...'
                                : 'Nhập từ khoá để tìm phản ánh.',
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
}
