import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/vcore_profile_family_info_controller.dart';
import 'vcore_profile_dropdownfield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfileFamilyThanhphanWidget extends StatelessWidget {
  const VcoreProfileFamilyThanhphanWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfileFamilyInfoController controller = Get.find();

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VcoreProfileInfoHeaderWidget(title: 'Thành phần gia đình'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VcoreProfileTextFieldWidget(
                  title: 'Thành phần gia đình',
                  hintText: 'Nhập thành phần gia đình',
                  value: controller.sinvienEdit.value.thanhPhanGiaDinh ?? '',
                  onChange: (text) {
                    controller.sinvienEdit.value.thanhPhanGiaDinh = text;
                  },
                  onSubmitted: (text) {},
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
