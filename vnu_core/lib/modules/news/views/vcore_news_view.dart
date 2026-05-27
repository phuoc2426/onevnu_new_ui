import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/news/controllers/vcore_news_controller.dart';
import 'package:vnu_core/modules/news/views/vcore_news_filter_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import 'vcore_news_detail_view.dart';
import 'vcore_news_item_widget.dart';

class VcoreNewsView extends GetView<VcoreNewsController> {
  const VcoreNewsView({super.key});

  @override
  Widget build(BuildContext context) {
    const normalColor = Color(0xff637392);
    const activeColor = Color(0xff003392);
    return GetBuilder(
      init: VcoreNewsController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listTinTuc.isEmpty) {
              controller.refreshData();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Danh sách tin tức',
            body: ContainerAutoDissmis(
              child: Obx(
                () => Column(
                  children: [
                    //Search
                    Container(
                      height: 64,
                      color: Colors.white,
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
                                    isDense: true,
                                    //Need for remove padding
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Nhập tiêu đề tin',
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0.0),
                                child: svgAsset('assets/images/ic_search.svg'),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6.0),
                                child: svgAction(
                                  'assets/images/ic_filter.svg',
                                  color: controller.isFilter.value
                                      ? activeColor
                                      : normalColor,
                                  action: () {
                                    Utils.hideKeyboard();

                                    Get.dialog(
                                      Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: VcoreNewsFilterWidget(
                                            controller: controller,
                                          ),
                                        ),
                                      ),
                                    );
                                    controller.isFilter.toggle();
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    //List
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: SmartRefresher(
                          controller: controller.refreshController,
                          enablePullUp: true,
                          onRefresh: controller.refreshData,
                          onLoading: controller.loadMoreData,
                          header: const WaterDropHeader(),
                          footer: const RefreshFooterWidget(),
                          child: controller.listTinTuc.isNotEmpty
                              ? ListView.separated(
                                  padding: EdgeInsets.only(
                                    bottom: floatingNavBottomPadding(context),
                                  ),
                                  itemBuilder: (ctx, index) {
                                    TinTucModel tinTucModel =
                                        controller.listTinTuc[index];
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        Utils.hideKeyboard();
                                        Get.to(
                                          () => VcoreNewsDetailView(
                                            tinTucModel: tinTucModel,
                                          ),
                                        );
                                      },
                                      child: VcoreNewsItemWidget(
                                        tinTucModel: tinTucModel,
                                      ),
                                    );
                                  },
                                  separatorBuilder: (_, __) => spaceHeight(10),
                                  itemCount: controller.listTinTuc.length,
                                )
                              : Text(
                                  'Không có kết quả phù hợp với tiêu chí tìm kiếm',
                                  style: TextStyles.T14M,
                                ),
                        ),
                      ),
                    )
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
