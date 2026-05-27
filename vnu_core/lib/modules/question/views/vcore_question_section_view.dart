import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/hoi_dap_model.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/modules/question/controllers/vcore_question_controller.dart';
import 'package:vnu_core/modules/question/views/vcore_question_detail_view.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import 'vcore_input_date_week_widget.dart';
import 'vcore_question_item_widget.dart';

class VcoreQuestionSectionView extends GetView<VcoreQuestionController> {
  final String trangThai;

  const VcoreQuestionSectionView({super.key, required this.trangThai});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreQuestionController(),
      tag: const Uuid().v4(),
      builder: (controller) => ProgressHubWidget(
        contextComplete: (hubContext) {
          controller.context = hubContext;
          controller.trangThai = trangThai;
          if (controller.currentChuDe.value == null) {
            controller.getTatCaChuDe();
          }
        },
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      VcoreDropdownSelectWidget(
                        items: controller.listChuDe
                            .map((e) => e.tenChuDe ?? '')
                            .toList(),
                        hint: 'Tất cả chủ đề',
                        value: controller.currentChuDe.value?.tenChuDe,
                        onSelected: (value) {
                          controller.changeChuDe(value);
                        },
                      ),
                      spaceHeight(8),
                      VcoreInputDateWeekWidget(
                        startTime: controller.startDate.value,
                        endTime: controller.endDate.value,
                        onSelectDate: () async {
                          var results = await showCalendarDatePicker2Dialog(
                            context: context,
                            config: CalendarDatePicker2WithActionButtonsConfig(
                              calendarType: CalendarDatePicker2Type.single,
                              currentDate: controller.startDate.value,
                              firstDayOfWeek: 1,
                            ),
                            dialogSize: const Size(325, 400),
                            // value: _dates,
                            borderRadius: BorderRadius.circular(15),
                          );
                          if (results?.first != null) {
                            controller.changeDate(results!.first!, true);
                          }
                        },
                        onPrevious: () {
                          if (controller.startDate.value != null) {
                            controller.changeDate(
                              controller.startDate.value!
                                  .add(const Duration(days: -2)),
                              true,
                            );
                          }
                        },
                        onNext: () {
                          if (controller.endDate.value != null) {
                            controller.changeDate(
                              controller.endDate.value!
                                  .add(const Duration(days: 2)),
                              true,
                            );
                          }
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
                      enablePullUp: true,
                      onRefresh: controller.refreshData,
                      onLoading: controller.loadMoreData,
                      header: const WaterDropHeader(),
                      footer: const RefreshFooterWidget(),
                      child: ListView.separated(
                          itemCount: controller.listQuestion.length,
                          separatorBuilder: (context, index) => spaceHeight(16),
                          itemBuilder: (ctx, index) {
                            HoiDapModel question =
                                controller.listQuestion[index];
                            return InkWell(
                              onTap: () async {
                                var result =
                                    await Get.to(() => VcoreQuestionDetailView(
                                          question: question,
                                        ));
                                if (result == true) {
                                  controller.listQuestion.removeAt(index);
                                }
                              },
                              child: VcoreQuestionItemWidget(
                                question: question,
                              ),
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
  }
}
