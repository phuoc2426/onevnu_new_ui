import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import '../../controllers/vcore_profile_family_info_controller.dart';
import 'vcore_profile_info_header_widget.dart';

class VcoreProfileFamilyConWidget extends StatelessWidget {
  const VcoreProfileFamilyConWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfileFamilyInfoController controller = Get.find();

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VcoreProfileInfoHeaderWidget(title: 'Thông tin các con'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              VcoreProfileTextFieldWidget(
                title: 'Thông tin các con',
                hintText: 'Nhập thông tin các con',
                maxLine: 5,
                value: controller.sinvienEdit.value.conCai ?? '',
                onChange: (text) {
                  controller.sinvienEdit.value.conCai = text;
                },
                onSubmitted: (text) {},
              ),
            ]),
          )
        ],
      ),
    );
  }
}
