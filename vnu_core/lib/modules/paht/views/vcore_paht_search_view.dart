import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_detail_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_item_widget.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import '../controllers/vcore_paht_search_controller.dart';

class VcorePahtSearchView extends GetView<VcorePahtSearchController> {
  const VcorePahtSearchView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcorePahtSearchController(),
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
            appBar: AppBar(
              backgroundColor: const Color(0xff007F3E),
              flexibleSpace: Container(
                child: svgAsset('assets/images/bg_navi.svg',
                    height: 120, fit: BoxFit.cover),
              ),
              centerTitle: false,
              shadowColor: Colors.transparent,
              titleSpacing: 0.0,
              title: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.textEditingController,
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung tìm kiếm',
                          border: InputBorder.none,
                          isDense: true, //Need for remove padding
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          hintStyle: TextStyles.regular
                              .copyWith(color: const Color(0xff879ABF)),
                          labelStyle:
                              TextStyles.regular.copyWith(color: Colors.black),
                        ),
                        onSubmitted: (value) {
                          Utils.hideKeyboard();
                          controller.refreshData();
                        },
                      ),
                    ),
                    svgAsset('assets/images/ic_search.svg'),
                    spaceWidth(10),
                  ],
                ),
              ),
            ),
            body: Obx(
              () => controller.listPaht.isNotEmpty
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
                                    isChuaXuLy: false,
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
                      child: controller.isLoading.value
                          ? spaceHeight(0)
                          : Text(
                              "Không có dữ liệu",
                              style: TextStyles.regular,
                            ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
