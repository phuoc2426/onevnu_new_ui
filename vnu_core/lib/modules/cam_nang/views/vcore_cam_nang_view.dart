import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/cam_nang/controllers/vcore_cam_nang_controller.dart';
import 'package:vnu_core/screens/vcore_preview_pdf_screen.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../../../widgets/refresher_footer_widget.dart';
import 'vcore_cam_nang_detail_view.dart';
import 'vcore_cam_nang_item_widget.dart';

class VcoreCamNangView extends GetView<VcoreCamNangController> {
  const VcoreCamNangView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreCamNangController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listCamNang.isEmpty) {
              controller.refreshData();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Danh sách cẩm nang',
            body: ContainerAutoDissmis(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.white,
                    child: //Search form
                        Center(
                      child: Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xff879ABF))),
                          child: Row(
                            children: [
                              spaceWidth(10),
                              Expanded(
                                  child: TextField(
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    //Need for remove padding
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Nhập tiêu đề cẩm nang',
                                    hintStyle: TextStyles.regular
                                        .copyWith(color: Colors.black),
                                    labelStyle: TextStyles.regular
                                        .copyWith(color: Colors.black)),
                                controller: controller.textEditingController,
                                onSubmitted: (value) {
                                  print('Search for key --> $value');
                                  controller.refreshData();
                                },
                              )),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: svgAsset('assets/images/ic_search.svg'),
                              )
                            ],
                          )),
                    ),
                    //Nhập tiêu đề cẩm nang
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Obx(
                      () => SmartRefresher(
                        controller: controller.refreshController,
                        enablePullUp: true,
                        onRefresh: controller.refreshData,
                        onLoading: controller.loadMoreData,
                        header: const WaterDropHeader(),
                        footer: const RefreshFooterWidget(),
                        child: controller.listCamNang.isNotEmpty
                            ? ListView.separated(
                                itemBuilder: (ctx, index) {
                                  var model = controller.listCamNang[index];
                                  return GestureDetector(
                                      onTap: () {
                                        Utils.hideKeyboard();

                                        Get.to(() =>
                                            const VcoreCamNangDetailView());
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: InkWell(
                                        onTap: () {
                                          Utils.hideKeyboard();
                                          //
                                          Get.to(() => VCorePreviewPdfScreen(
                                              title: model.tieuDe,
                                              fileId: model.guidFileCamNangs
                                                      ?.first ??
                                                  ''));
                                        },
                                        child: VcoreCamNangItemWidget(
                                          camNangModel: model,
                                        ),
                                      ));
                                },
                                separatorBuilder: (_, __) => spaceHeight(16),
                                itemCount: controller.listCamNang.length,
                              )
                            : Text(
                                'Không có kết quả phù hợp với tiêu chí tìm kiếm',
                                style: TextStyles.T14M),
                      ),
                    ),
                  ))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
