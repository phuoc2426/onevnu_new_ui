import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';

import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonPhoneWidget extends StatelessWidget {
  const VcoreProfilePersonPhoneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller = Get.find();

    const itemSpace = 16.0;
    return Obx(
      () => Container(
          color: Colors.white,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const VcoreProfileInfoHeaderWidget(title: 'Điện thoại liên lạc'),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  VcoreProfileTextFieldWidget(
                    title: 'Số di động',
                    hintText: 'Nhập số di động',
                    value: controller.sinhvienEdit.value.mobile ?? '',
                    onChange: (text) {
                      controller.sinhvienEdit.value.mobile = text;
                    },
                    onSubmitted: (text) {},
                  ),
                  spaceHeight(itemSpace),
                  VcoreProfileTextFieldWidget(
                    title: 'Số nhà riêng',
                    hintText: 'Nhập số nhà riêng',
                    value: controller.sinhvienEdit.value.tel ?? '',
                    onChange: (text) {
                      controller.sinhvienEdit.value.tel = text;
                    },
                    onSubmitted: (text) {},
                  ),
                ]))
          ])),
    );
  }
}
