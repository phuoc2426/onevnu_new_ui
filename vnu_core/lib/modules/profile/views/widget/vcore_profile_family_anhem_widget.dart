import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import '../../controllers/vcore_profile_family_info_controller.dart';
import 'vcore_profile_info_header_widget.dart';

class VcoreProfileFamilyAnhEmWidget extends StatelessWidget {
  const VcoreProfileFamilyAnhEmWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfileFamilyInfoController controller = Get.find();

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VcoreProfileInfoHeaderWidget(title: 'Thông tin của anh/chị/em'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              VcoreProfileTextFieldWidget(
                title: 'Thông tin của anh/chị/em',
                hintText: 'Nhập thông tin anh/chị/em',
                maxLine: 5,
                value: controller.sinvienEdit.value.ngheNghiepAnhEm ?? '',
                onChange: (text) {
                  controller.sinvienEdit.value.ngheNghiepAnhEm = text;
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
