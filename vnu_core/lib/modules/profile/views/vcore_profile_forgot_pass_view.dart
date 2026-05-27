import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_pass_controller.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import 'widget/vcore_profile_dropdownfield_widget.dart';

class VcoreProfileForgotPassView extends GetView<VcoreProfilePassController> {
  const VcoreProfileForgotPassView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreProfilePassController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Quên mật khẩu',
            ),
            backgroundColor: AppColor.bgColor,
            body: Obx(
              () => Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hinh thu
                    VcoreProfileDropdownfieldWidget(
                      title: 'Loại mật khẩu',
                      hintText: 'Chọn loại mật khẩu',
                      value: controller.loaiMatKhau.value?.label,
                      items: controller.listLoaiMatKhau
                          .map((e) => e.label ?? '')
                          .toList(),
                      onSelected: (value) {
                        LoaiMatKhauModel? obj =
                            controller.listLoaiMatKhau.firstWhereOrNull((e) {
                          return e.label == value;
                        });
                        if (obj != null) {
                          controller.loaiMatKhau.value = obj;
                        }
                      },
                    ),
                    spaceHeight(40),
                    //
                    BlueButton(
                      title: 'Gửi',
                      width: 200,
                      action: () {
                        //
                        controller.quenMatKhau();
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
