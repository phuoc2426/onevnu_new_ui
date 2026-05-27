import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/exam_schedule/controllers/vcore_exam_schedule_controller.dart';
import 'package:vnu_noi_tru/modules/boarding/controllers/nt_boarding_controller.dart';

import 'nt_boarding_detail_view.dart';
import 'nt_boarding_item_widget.dart';

class NtBoardingListWidget extends GetView<NtBoardingController> {
  const NtBoardingListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreExamScheduleController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
              itemBuilder: (ctx, index) {
                return GestureDetector(
                    onTap: () {
                      Get.to(() => NtBoardingDetailView());
                    },
                    child: const NtBoardingItemWidget());
              },
              separatorBuilder: (_, __) => spaceHeight(13),
              itemCount: 3),
        );
      },
    );
  }
}
