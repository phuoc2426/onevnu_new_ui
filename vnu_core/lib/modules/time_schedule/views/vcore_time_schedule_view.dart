import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../../../common/space_widget.dart';
import '../../exam_schedule/views/vcore_dropdown_select_widget.dart';
import '../controllers/vcore_time_schedule_controller.dart';
import 'vcore_time_schedule_section_widget.dart';

class VcoreTimeScheduleView extends GetView<VcoreTimeScheduleController> {
  const VcoreTimeScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreTimeScheduleController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.danhSachKieuTruong.isEmpty) {
              controller.getDanhSachKieuTruong();
            }
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Xem lịch thi',
            ),
            backgroundColor: AppColor.bgColor,
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                            items: controller.danhSachKieuTruong
                                .map((e) => e.toDisplayName())
                                .toList(),
                            hint: 'Chọn trường',
                            value: controller.kieuTruong.value?.toDisplayName(),
                            onSelected: (value) async {
                              await controller.changeKieuTruong(value);
                            },
                          ),
                          spaceHeight(8),
                          VcoreDropdownSelectWidget(
                            items: controller.danhSachHocKy
                                .map((e) => e.disPlayName())
                                .toList(),
                            hint: 'Chọn kỳ',
                            value: controller.hocKy.value?.disPlayName(),
                            onSelected: (value) {
                              controller.changeHocKy(value);
                            },
                          ),
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
                          onRefresh: controller.refreshData,
                          header: const WaterDropHeader(),
                          child: ListView.separated(
                              itemCount: controller.mapLichThiHocKy.keys
                                  .toList()
                                  .length,
                              separatorBuilder: (context, index) =>
                                  spaceHeight(16),
                              itemBuilder: (ctx, index) {
                                String key = controller.mapLichThiHocKy.keys
                                    .toList()[index];

                                return VcoreTimeScheduleSectionWidget(
                                  date: key,
                                  lichThi:
                                      controller.mapLichThiHocKy[key] ?? [],
                                );
                              }),
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
}
