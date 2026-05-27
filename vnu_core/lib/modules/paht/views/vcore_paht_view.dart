import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_comunitation_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_create_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_person_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_search_view.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

import '../controllers/vcore_paht_controller.dart';

class VcorePahtView extends GetView<VcorePahtController> {
  const VcorePahtView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcorePahtController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return VcoreModuleScaffold(
          title: 'Phản ánh hiện trường',
          actions: [
            IconButton(
                onPressed: () {
                  Get.to(() => VcorePahtSearchView());
                },
                icon: svgAsset('assets/images/ic_search.svg',
                    color: Colors.black87, width: 28))
          ],
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    VcorePahtComunitationView(),
                    VcorePahtPersonView()
                  ],
                ),
              ),
              Container(
                // height: 90,
                color: const Color(0xffD9D9D9),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                ),
                // margin: const EdgeInsets.only(top: 30),
                child: Stack(
                  alignment: AlignmentDirectional.topCenter,
                  children: [
                    Column(
                      children: [
                        SafeArea(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  controller.pageController.jumpToPage(0);
                                },
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.groups_rounded,
                                      size: 40,
                                      color: AppTheme.colorMain,
                                    ),
                                    Text(
                                      'Cộng đồng',
                                      style: TextStyles.regular,
                                    )
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Get.to(() => const VcorePahtCreateView());
                                },
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.add_circle_rounded,
                                      size: 50,
                                      color: AppTheme.colorMain,
                                    ),
                                    Text(
                                      'Tạo phản ánh',
                                      style: TextStyles.regular,
                                    )
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  controller.pageController.jumpToPage(1);
                                },
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.person_rounded,
                                      size: 30,
                                      color: AppTheme.colorMain,
                                    ),
                                    Text(
                                      'Cá nhân',
                                      style: TextStyles.regular,
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
