import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/thu_tuc_mot_cua_model.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/modules/one_door/views/vcore_one_door_detail_view.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import '../../../common/app_text_styles.dart';
import '../../../common/space_widget.dart';
import '../controllers/vcore_one_door_controller.dart';

class VcoreOneDoorView extends GetView<VcoreOneDoorController> {
  const VcoreOneDoorView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreOneDoorController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listLinhVuc.isEmpty) {
              controller.getTatCaLinhVuc();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Thủ tục một cửa',
            body: ContainerAutoDissmis(
              child: Obx(
                () => Column(
                  children: [
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          VcoreDropdownSelectWidget(
                            value: controller.currentLinhVuc.value?.tenLinhVuc,
                            items: controller.listLinhVuc.map((e) {
                              return e.tenLinhVuc ?? '';
                            }).toList(),
                            hint: 'Chọn lĩnh vực',
                            onSelected: (value) {
                              controller.changeLinhVuc(value);
                            },
                          ),
                          spaceHeight(8),
                          //Search form
                          Container(
                              width: double.infinity,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xff879ABF))),
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
                                        hintText: 'Nhập tiêu đề thủ tục',
                                        hintStyle: TextStyles.regular
                                            .copyWith(color: Colors.black),
                                        labelStyle: TextStyles.regular
                                            .copyWith(color: Colors.black)),
                                    controller:
                                        controller.textEditingController,
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
                              ))
                        ],
                      ),
                    ),
                    spaceHeight(16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: SmartRefresher(
                          controller: controller.refreshController,
                          enablePullUp: true,
                          onRefresh: controller.refreshData,
                          onLoading: controller.loadMoreData,
                          header: const WaterDropHeader(),
                          footer: const RefreshFooterWidget(),
                          child: controller.listThuTucMotCua.isNotEmpty
                              ? ListView.separated(
                                  itemCount: controller.listThuTucMotCua.length,
                                  separatorBuilder: (context, index) =>
                                      spaceHeight(16),
                                  itemBuilder: (ctx, index) {
                                    Utils.hideKeyboard();
                                    ThuTucMotCuaModel thutuc =
                                        controller.listThuTucMotCua[index];
                                    return GestureDetector(
                                        onTap: () {
                                          Get.to(() => VcoreOneDoorDetailView(
                                                thuTucMotCuaModel: thutuc,
                                              ));
                                        },
                                        child: oneDoorItem(thutuc));
                                  })
                              : Text(
                                  'Không có kết quả phù hợp với tiêu chí tìm kiếm',
                                  style: TextStyles.T14M),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget oneDoorItem(ThuTucMotCuaModel thutuc) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lĩnh vực: ${thutuc.tenLinhVuc}',
            style: TextStyles.regular.copyWith(color: const Color(0xff5776B7)),
          ),
          spaceHeight(10),
          Text(
            thutuc.tenThuTuc ?? '',
            style: TextStyles.regular
                .copyWith(fontSize: 16, color: const Color(0xff003392)),
          ),
        ],
      ),
    );
  }
}
