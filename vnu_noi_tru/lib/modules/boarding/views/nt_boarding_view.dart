import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_noi_tru/modules/boarding/controllers/nt_boarding_controller.dart';

import 'nt_boading_register_view.dart';
import 'nt_boarding_list_widget.dart';

class NtBoardingView extends GetView<NtBoardingController> {
  const NtBoardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: NtBoardingController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Danh sách phiếu đăng ký nội trú',
              leftAction: const BackButton(),
            ),
            backgroundColor: AppColor.bgColor,
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    height: 46,
                    width: double.infinity,
                    color: Colors.white,
                    child: TabBar(
                      labelColor: const Color(0xff003392),
                      unselectedLabelColor: const Color(0xff879ABF),
                      indicatorColor: const Color(0xff003392),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: TextStyles.semiBold.copyWith(fontSize: 16),
                      tabs: const [
                        Tab(
                          text: 'Lưu nháp',
                        ),
                        Tab(
                          text: 'Đã gửi',
                        ),
                      ],
                    ),
                  ),
                  // content
                  const Expanded(
                      child: TabBarView(children: [
                    NtBoardingListWidget(),
                    NtBoardingListWidget()
                  ]))
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
                  Get.to(() => const NtBoadingRegisterView());
                },
                child: Center(
                  child: Text(
                    'Đăng ký',
                    style: TextStyles.semiBold.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
