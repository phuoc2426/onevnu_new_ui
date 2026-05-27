import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/hdsd_model.dart';
import 'package:vnu_core/screens/vcore_preview_pdf_screen.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import '../controllers/vcore_hdsd_controller.dart';

class VcoreHdsdView extends GetView<VcoreHdsdController> {
  const VcoreHdsdView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreHdsdController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listHdsd.isEmpty) {
              controller.refreshData();
            }
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Hướng dẫn sử dụng',
            ),
            backgroundColor: AppColor.bgColor,
            body: Column(
              children: [
                Container(
                  height: 55,
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      'HƯỚNG DẪN SỬ DỤNG ỨNG DỤNG ONEVNU',
                      style: TextStyles.semiBold
                          .copyWith(color: const Color(0xff003392)),
                    ),
                  ),
                ),
                spaceHeight(16),
                Expanded(
                    child: Container(
                  color: Colors.white,
                  child: Obx(
                    () => SmartRefresher(
                      controller: controller.refreshController,
                      enablePullUp: true,
                      onRefresh: controller.refreshData,
                      // onLoading: controller.loadMoreData,
                      header: const WaterDropHeader(),
                      footer: const RefreshFooterWidget(),
                      child: ListView.separated(
                          itemBuilder: (ctx, index) {
                            HdsdModel model = controller.listHdsd[index];
                            return InkWell(
                              onTap: () {
                                Get.to(() => VCorePreviewPdfScreen(
                                    title: model.name,
                                    fileId: model.guid ?? ''));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Text(
                                  model.name ?? '',
                                  style: TextStyles.italic
                                      .copyWith(color: Colors.orange),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => spaceHeight(0),
                          itemCount: controller.listHdsd.length),
                    ),
                  ),
                ))
              ],
            ),
          ),
        );
      },
    );
  }
}
