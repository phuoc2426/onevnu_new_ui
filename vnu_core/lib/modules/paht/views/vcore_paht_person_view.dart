import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/paht/controllers/vcore_paht_person_controller.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_detail_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_item_widget.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import '../../exam_schedule/views/vcore_dropdown_select_widget.dart';

class VcorePahtPersonView extends StatelessWidget {
  const VcorePahtPersonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: const Color(0xff003392),
              unselectedLabelColor: const Color(0xff879ABF),
              indicatorColor: const Color(0xff003392),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyles.semiBold.copyWith(fontSize: 16),
              tabs: const [
                Tab(
                  text: 'Chưa xử lý',
                ),
                Tab(
                  text: 'Đã xử lý',
                ),
              ],
            ),
            // content
            const Expanded(
              child: TabBarView(
                children: [
                  VcorePahtPersonListView(
                    trangThaiXuLy: 'ChuaTraLoi',
                  ),
                  VcorePahtPersonListView(
                    trangThaiXuLy: 'DaTraLoi',
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class VcorePahtPersonListView extends GetView<VcorePahtPersonController> {
  final String trangThaiXuLy;
  const VcorePahtPersonListView({super.key, required this.trangThaiXuLy});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcorePahtPersonController(trangThaiXuLy),
      tag: const Uuid().v4(),
      builder: (controller) {
        if (controller.listPaht.isEmpty) {
          controller.refreshData();
        }
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Obx(
              () => Column(
                children: [
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
                                    onTap: () async {
                                      var result = await Get.to(
                                        () => VcorePahtDetailView(
                                          phanAnhHienTruongModel:
                                              controller.listPaht[index],
                                          isChuaXuLy:
                                              trangThaiXuLy == 'ChuaTraLoi',
                                        ),
                                      );
                                      if (result == true) {
                                        controller.refreshData();
                                      }
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
