import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_datefield_widget.dart';
import '../../controllers/vcore_profile_family_info_controller.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfileFamilyVoChongWidget extends StatelessWidget {
  const VcoreProfileFamilyVoChongWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfileFamilyInfoController controller = Get.find();

    const itemSpace = 16.0;
    return Container(
      color: Colors.white,
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VcoreProfileInfoHeaderWidget(title: 'Thông tin của vợ/chồng'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                VcoreProfileTextFieldWidget(
                    title: 'Họ và tên',
                    hintText: 'Nhập họ và tên',
                    value: controller.sinvienEdit.value.hoVaTenVoChong ?? '',
                    onChange: (text) {
                      controller.sinvienEdit.value.hoVaTenVoChong = text;
                    },
                    onSubmitted: (text) {}),
                spaceHeight(itemSpace),

                // Nam sinh
                Row(
                  children: [
                    Expanded(
                      child: VcoreProfileDatefieldWidget(
                        title: 'Ngày sinh',
                        hintText: 'Nhập ngày sinh',
                        value: controller.sinvienEdit.value.ngaySinhVoChong,
                        onChangeDate: (selectedDate) {
                          controller.sinvienEdit.update((item) {
                            item?.ngaySinhVoChong = selectedDate;
                          });
                        },
                      ),
                    ),
                    spaceWidth(10),
                    Expanded(
                      child: VcoreProfileTextFieldWidget(
                        title: 'Nghề nghiệp',
                        hintText: 'Nhập nghề nghiệp',
                        value: controller.sinvienEdit.value.ngheNghiepVoChong ??
                            '',
                        onChange: (text) {
                          controller.sinvienEdit.value.ngheNghiepVoChong = text;
                        },
                        onSubmitted: (text) {},
                      ),
                    ),
                  ],
                ),
                spaceHeight(itemSpace),

                VcoreProfileTextFieldWidget(
                  title: 'Địa chỉ',
                  hintText: 'Nhập địa chỉ',
                  value: controller.sinvienEdit.value.diaChiVoChong ?? '',
                  onChange: (text) {
                    controller.sinvienEdit.value.diaChiVoChong = text;
                  },
                  onSubmitted: (text) {},
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
