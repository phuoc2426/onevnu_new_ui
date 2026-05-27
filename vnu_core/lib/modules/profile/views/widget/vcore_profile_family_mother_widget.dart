import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_family_info_controller.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfileFamilyMotherWidget extends StatelessWidget {
  const VcoreProfileFamilyMotherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfileFamilyInfoController controller = Get.find();

    const itemSpace = 16.0;
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VcoreProfileInfoHeaderWidget(title: 'Thông tin của mẹ'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              VcoreProfileTextFieldWidget(
                title: 'Họ và tên',
                hintText: 'Nhập họ và tên',
                value: controller.sinvienEdit.value.hoVaTenMe ?? '',
                onChange: (text) {
                  controller.sinvienEdit.value.hoVaTenMe = text;
                },
                onSubmitted: (text) {},
              ),
              spaceHeight(itemSpace),

              // Nam sinh
              Row(
                children: [
                  Expanded(
                    child: VcoreProfileTextFieldWidget(
                      title: 'Năm sinh',
                      hintText: 'Nhập năm sinh',
                      value: controller.sinvienEdit.value.ngaySinhMe ?? '',
                      onChange: (text) {
                        controller.sinvienEdit.value.ngaySinhMe = text;
                      },
                      onSubmitted: (text) {},
                    ),
                  ),
                  spaceWidth(10),
                  Expanded(
                    child: VcoreProfileTextFieldWidget(
                      title: 'Điện thoại',
                      hintText: 'Nhập điện thoại',
                      value: controller.sinvienEdit.value.dienThoaiMe ?? '',
                      onChange: (text) {
                        controller.sinvienEdit.value.dienThoaiMe = text;
                      },
                      onSubmitted: (text) {},
                    ),
                  ),
                ],
              ),
              spaceHeight(itemSpace),

              // Nam sinh
              Row(
                children: [
                  Expanded(
                    child: VcoreProfileTextFieldWidget(
                      title: 'Nghề nghiệp',
                      hintText: 'Nhập nghề nghiệp',
                      value: controller.sinvienEdit.value.ngheNghiepMe ?? '',
                      onChange: (text) {
                        controller.sinvienEdit.value.ngheNghiepMe = text;
                      },
                      onSubmitted: (text) {},
                    ),
                  ),
                  spaceWidth(10),
                  Expanded(
                    child: VcoreProfileTextFieldWidget(
                      title: 'Thư điện tử',
                      hintText: 'Nhập thư điện tử',
                      value: controller.sinvienEdit.value.emailMe ?? '',
                      onChange: (text) {
                        controller.sinvienEdit.value.emailMe = text;
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
                value: controller.sinvienEdit.value.diaChiMe ?? '',
                onChange: (text) {
                  controller.sinvienEdit.value.diaChiMe = text;
                },
                onSubmitted: (text) {},
              ),
              spaceHeight(itemSpace),

              VcoreProfileTextFieldWidget(
                title: 'Nguyên quán',
                hintText: 'Nhập nguyên quán',
                value: controller.sinvienEdit.value.nguyenQuanMe ?? '',
                onChange: (text) {
                  controller.sinvienEdit.value.nguyenQuanMe = text;
                },
                onSubmitted: (text) {},
              ),
              spaceHeight(itemSpace),

              VcoreProfileTextFieldWidget(
                title: 'Nơi công tác',
                hintText: 'Nhập nơi công tác',
                value: controller.sinvienEdit.value.diaChiCoQuanMe ?? '',
                onChange: (text) {
                  controller.sinvienEdit.value.diaChiCoQuanMe = text;
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
