import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/loai_mat_khau_model.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_pass_controller.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_forgot_pass_view.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

import 'widget/vcore_profile_dropdownfield_widget.dart';
import 'widget/vcore_profile_textfield_widget.dart';

class VcoreProfileChangePassView extends GetView<VcoreProfilePassController> {
  const VcoreProfileChangePassView({super.key});

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
          child: VcoreModuleScaffold(
            title: 'Đổi mật khẩu',
            body: ContainerAutoDissmis(
              child: SingleChildScrollView(
                child: Obx(
                  () => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
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
                            LoaiMatKhauModel? obj = controller.listLoaiMatKhau
                                .firstWhereOrNull((e) {
                              return e.label == value;
                            });
                            if (obj != null) {
                              controller.loaiMatKhau.value = obj;
                            }
                          },
                        ),
                        spaceHeight(10),

                        // Mat khau cu
                        VcoreProfileTextFieldWidget(
                          title: 'Nhập mật khẩu cũ',
                          hintText: 'Nhập mật khẩu cũ',
                          onChange: (text) {
                            controller.oldPassword = text.trim();
                          },
                          onSubmitted: (text) {
                            controller.oldPassword = text.trim();
                          },
                        ),
                        spaceHeight(10),

                        VcoreProfileTextFieldWidget(
                          title: 'Nhập mật khẩu mới',
                          hintText: 'Nhập mật khẩu mới',
                          onChange: (text) {
                            controller.newPassword = text.trim();
                          },
                          onSubmitted: (text) {
                            controller.newPassword = text.trim();
                          },
                        ),
                        spaceHeight(10),

                        VcoreProfileTextFieldWidget(
                          title: 'Nhập lại mật khẩu mới',
                          hintText: 'Nhập lại mật khẩu mới',
                          onChange: (text) {
                            controller.reNewPassword = text.trim();
                          },
                          onSubmitted: (text) {
                            controller.reNewPassword = text.trim();
                          },
                        ),
                        spaceHeight(10),

                        Row(
                          children: [
                            const Spacer(),
                            TextButton(
                                onPressed: () {
                                  Get.to(
                                      () => const VcoreProfileForgotPassView());
                                },
                                child: Text(
                                  'Quên mật khẩu',
                                  style: TextStyles.semiBold.copyWith(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue,
                                  ),
                                ))
                          ],
                        ),

                        spaceHeight(30),

                        BlueButton(
                          title: 'Đổi mật khẩu',
                          width: 200,
                          action: () {
                            controller.thayDoiMatKhau();
                          },
                        )
                      ],
                    ),
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
