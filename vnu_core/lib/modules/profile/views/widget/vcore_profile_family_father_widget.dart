import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_family_info_controller.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfileFamilyFatherWidget extends StatelessWidget {
  const VcoreProfileFamilyFatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfileFamilyInfoController controller = Get.find();

    const itemSpace = 16.0;
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VcoreProfileInfoHeaderWidget(title: 'Thông tin của cha'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              VcoreProfileTextFieldWidget(
                  title: 'Họ và tên',
                  hintText: 'Nhập họ và tên',
                  value: controller.sinvienEdit.value.hoVaTenCha ?? '',
                  onChange: (text) {
                    controller.sinvienEdit.value.hoVaTenCha = text;
                  },
                  onSubmitted: (text) {}),
              spaceHeight(itemSpace),

              // Nam sinh
              Row(
                children: [
                  Expanded(
                    child: VcoreProfileTextFieldWidget(
                        title: 'Năm sinh',
                        hintText: 'Nhập năm sinh',
                        value: controller.sinvienEdit.value.ngaySinhCha ?? '',
                        onChange: (text) {
                          controller.sinvienEdit.value.ngaySinhCha = text;
                        },
                        onSubmitted: (text) {}),
                  ),
                  spaceWidth(10),
                  Expanded(
                    child: VcoreProfileTextFieldWidget(
                        title: 'Điện thoại',
                        hintText: 'Nhập điện thoại',
                        value: controller.sinvienEdit.value.dienThoaiCha ?? '',
                        onChange: (text) {
                          controller.sinvienEdit.value.dienThoaiCha = text;
                        },
                        onSubmitted: (text) {}),
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
                        value: controller.sinvienEdit.value.ngheNghiepCha ?? '',
                        onChange: (text) {
                          controller.sinvienEdit.value.ngheNghiepCha = text;
                        },
                        onSubmitted: (text) {}),
                  ),
                  spaceWidth(10),
                  Expanded(
                    child: VcoreProfileTextFieldWidget(
                        title: 'Thư điện tử',
                        hintText: 'Nhập thư điện tử',
                        value: controller.sinvienEdit.value.emailCha ?? '',
                        onChange: (text) {
                          controller.sinvienEdit.value.emailCha = text;
                        },
                        onSubmitted: (text) {}),
                  ),
                ],
              ),
              spaceHeight(itemSpace),

              VcoreProfileTextFieldWidget(
                  title: 'Địa chỉ',
                  hintText: 'Nhập địa chỉ',
                  value: controller.sinvienEdit.value.diaChiCha ?? '',
                  onChange: (text) {
                    controller.sinvienEdit.value.diaChiCha = text;
                  },
                  onSubmitted: (text) {}),
              spaceHeight(itemSpace),

              VcoreProfileTextFieldWidget(
                  title: 'Nguyên quán',
                  hintText: 'Nhập nguyên quán',
                  value: controller.sinvienEdit.value.nguyenQuanCha ?? '',
                  onChange: (text) {
                    controller.sinvienEdit.value.nguyenQuanCha = text;
                  },
                  onSubmitted: (text) {}),
              spaceHeight(itemSpace),

              VcoreProfileTextFieldWidget(
                  title: 'Nơi công tác',
                  hintText: 'Nhập nơi công tác',
                  value: controller.sinvienEdit.value.diaChiCoQuanCha ?? '',
                  onChange: (text) {
                    controller.sinvienEdit.value.diaChiCoQuanCha = text;
                  },
                  onSubmitted: (text) {}),
            ]),
          )
        ],
      ),
    );
  }
}
