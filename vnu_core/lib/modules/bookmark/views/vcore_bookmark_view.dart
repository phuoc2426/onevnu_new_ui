import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/lien_ket_danh_dau_model.dart';
import 'package:vnu_core/modules/bookmark/controllers/vcore_bookmark_controller.dart';
import 'package:vnu_core/modules/bookmark/views/vcrore_bookmark_item_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';

import '../../../widgets/buttons_widget.dart';

class VcoreBookmarkView extends GetView<VcoreBookmarkController> {
  const VcoreBookmarkView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreBookmarkController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listLienKetDanhDau.isEmpty) {
              controller.refreshData();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Liên kết đánh dấu',
            body: ContainerAutoDissmis(
              child: Obx(
                () => Column(
                  children: [
                    Container(
                      color: Colors.white,
                      height: 71,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
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
                                      isDense: true, //Need for remove padding
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Nhập tiêu đề liên kết',
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
                                  child:
                                      svgAsset('assets/images/ic_search.svg'),
                                )
                              ],
                            )),
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SmartRefresher(
                        controller: controller.refreshController,
                        enablePullUp: true,
                        onRefresh: controller.refreshData,
                        onLoading: controller.loadMoreData,
                        header: const WaterDropHeader(),
                        footer: const RefreshFooterWidget(),
                        child: ListView.separated(
                            itemBuilder: (ctx, index) {
                              LienKetDanhDauModel lienKetDanhDauModel =
                                  controller.listLienKetDanhDau[index];
                              return VcoreBookmarkItemWidget(
                                lienKetDanhDauModel: lienKetDanhDauModel,
                                onEdit: () {
                                  showDialog(
                                      context: context,
                                      builder: (ctx) {
                                        controller.editTitleController.text =
                                            lienKetDanhDauModel.tenLienKet ??
                                                '';
                                        return Dialog(
                                          child: Container(
                                            // height: 400,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Center(
                                                  child: Text(
                                                    'Chỉnh sửa tiêu đề bài viết',
                                                    style: TextStyles.bold
                                                        .copyWith(
                                                            color: const Color(
                                                                0xff003392),
                                                            fontSize: 15),
                                                  ),
                                                ),
                                                // Input content
                                                Container(
                                                  height: 120,
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 35,
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      8,
                                                    ),
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xff879ABF),
                                                    ),
                                                  ),
                                                  child: TextField(
                                                    controller: controller
                                                        .editTitleController,
                                                    keyboardType:
                                                        TextInputType.multiline,
                                                    maxLines: null,
                                                    decoration:
                                                        const InputDecoration(
                                                      border: InputBorder.none,
                                                    ),
                                                  ),
                                                ),
                                                // Action
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: WhiteButton(
                                                        width: double.infinity,
                                                        title: 'Đóng',
                                                        action: () {
                                                          Get.back();
                                                        },
                                                      ),
                                                    ),
                                                    spaceWidth(22),
                                                    Expanded(
                                                      child: BlueButton(
                                                        width: double.infinity,
                                                        title: 'Lưu',
                                                        action: () {
                                                          Get.back();
                                                          controller.updateTitle(
                                                              lienKetDanhDauModel,
                                                              controller
                                                                  .editTitleController
                                                                  .text
                                                                  .trim());
                                                        },
                                                      ),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                },
                                onDelete: () {
                                  controller.deleteLienKet(lienKetDanhDauModel);
                                },
                              );
                            },
                            separatorBuilder: (_, id) => spaceHeight(10),
                            itemCount: controller.listLienKetDanhDau.length),
                      ),
                    ))
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
