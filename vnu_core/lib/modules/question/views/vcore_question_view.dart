import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/modules/question/controllers/vcore_question_controller.dart';
import 'package:vnu_core/modules/question/views/vcore_question_create_view.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

import 'vcore_question_section_view.dart';

class VcoreQuestionView extends GetView<VcoreQuestionController> {
  const VcoreQuestionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Câu hỏi của tôi',
      ),
      backgroundColor: AppColor.bgColor,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: const Color(0xff003392),
              unselectedLabelColor: const Color(0xff879ABF),
              indicatorColor: const Color(0xff003392),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyles.semiBold.copyWith(fontSize: AppFontSizes.large),
              tabs: const [
                Tab(
                  text: 'Chưa trả lời',
                ),
                Tab(
                  text: 'Đã trả lời',
                ),
              ],
            ),
            // content
            const Expanded(
              child: TabBarView(
                children: [
                  VcoreQuestionSectionView(
                    trangThai: 'ChuaTraLoi',
                  ),
                  VcoreQuestionSectionView(
                    trangThai: 'DaTraLoi',
                  )
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(65),
            color: const Color(0xff003392)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            //
            Get.to(() => const VcoreQuestionCreateView());
          },
          child: Center(
            child: Text(
              'Thêm mới',
              style: TextStyles.semiBold.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
