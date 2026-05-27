import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';

import 'vcore_profile_datefield_widget.dart';
import 'vcore_profile_info_header_widget.dart';

class VcoreProfilePersonDoanVienWidget extends StatelessWidget {
  const VcoreProfilePersonDoanVienWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller = Get.find();

    const itemSpace = 16.0;

    return Obx(
      () => Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VcoreProfileInfoHeaderWidget(title: 'Thông tin đoàn'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Row check box
                  InkWell(
                    onTap: () {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.isDoan =
                              !(controller.sinhvienEdit.value.isDoan ?? false);

                          if ((item?.isDoan ?? false) == false) {
                            item?.ngayVaoDoan = null;
                            item?.noiVaoDoan = "";
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Icon(
                            controller.sinhvienEdit.value.isDoan ?? false
                                ? Icons.check_box_rounded
                                : Icons
                                    .check_box_outline_blank_rounded, //check_box_outline_blank_rounded
                            color: const Color(0xff879ABF),
                          ),
                          spaceWidth(10),
                          Text('Là Đoàn viên',
                              style: TextStyles.regular
                                  .copyWith(color: Colors.black))
                        ],
                      ),
                    ),
                  ),

                  VcoreProfileTextFieldWidget(
                    title: 'Nơi vào Đoàn',
                    hintText: 'Nhập nơi vào Đoàn',
                    value: controller.sinhvienEdit.value.noiVaoDoan ?? '',
                    onChange: (text) {
                      controller.sinhvienEdit.value.noiVaoDoan = text;
                    },
                    onSubmitted: (text) {},
                  ),
                  spaceHeight(itemSpace),

                  VcoreProfileDatefieldWidget(
                    title: 'Ngày vào Đoàn',
                    hintText: 'Chọn ngày vào Đoàn',
                    value: controller.sinhvienEdit.value.ngayVaoDoan,
                    onChangeDate: (selectedDate) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.ngayVaoDoan = selectedDate;
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
