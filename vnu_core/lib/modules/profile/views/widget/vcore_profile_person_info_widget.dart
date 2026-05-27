import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_info_header_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';

import '../../controllers/vcore_profile_person_info_controller.dart';

class VcoreProfilePersonInfoWidget extends StatelessWidget {
  const VcoreProfilePersonInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller = Get.find();

    return Obx(
      () => Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VcoreProfileInfoHeaderWidget(title: 'Thông tin cá nhân'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VcoreProfileTextFieldWidget(
                      title: 'Mã sinh viên',
                      hintText: 'Mã sinh viên',
                      value:
                          Globals().thongTinSinhVienModel.value?.maSinhVien ??
                              '',
                      isDisable: true,
                      onSubmitted: (text) {}),
                  spaceHeight(10),
                  //
                  VcoreProfileTextFieldWidget(
                      title: 'Họ và tên',
                      hintText: 'Họ và tên',
                      value:
                          Globals().thongTinSinhVienModel.value?.hoVaTen ?? '',
                      isDisable: true,
                      onSubmitted: (text) {}),
                  spaceHeight(10),

                  //Ngay sinh - gioi tinh
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                            title: 'Ngày sinh',
                            hintText: 'Ngày sinh',
                            value: DateTimeUtils.stringFromDateTime(
                                Globals().thongTinSinhVienModel.value?.ngaySinh,
                                DateTimeConst.DATE_FORMAT),
                            isDisable: true,
                            onSubmitted: (text) {}),
                      ),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                            title: 'Giới tính',
                            hintText: 'Giới tính',
                            value: Globals()
                                    .thongTinSinhVienModel
                                    .value
                                    ?.gioiTinh ??
                                '',
                            isDisable: true,
                            onSubmitted: (text) {}),
                      )
                    ],
                  ),
                  spaceHeight(10),
                  // --

                  VcoreProfileTextFieldWidget(
                      title: 'Email ĐHQG',
                      hintText: 'Nhập email ĐHQG',
                      value: controller.sinhvienEdit.value.email ?? '',
                      onChange: (text) {
                        controller.sinhvienEdit.value.email = text;
                      },
                      isRequired: true,
                      onSubmitted: (text) {}),
                  spaceHeight(10),

                  // ----
                  VcoreProfileTextFieldWidget(
                      title: 'Email khác',
                      hintText: 'Nhập email khác',
                      value: controller.sinhvienEdit.value.emailKhac ?? '',
                      onChange: (text) {
                        controller.sinhvienEdit.value.emailKhac = text;
                      },
                      isRequired: true,
                      onSubmitted: (text) {}),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
