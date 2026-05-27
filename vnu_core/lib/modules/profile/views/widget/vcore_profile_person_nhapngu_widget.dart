import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_datefield_widget.dart';

import 'vcore_profile_info_header_widget.dart';

class VcoreProfilePersonNhapNguWidget extends StatelessWidget {
  const VcoreProfilePersonNhapNguWidget({super.key});

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
            const VcoreProfileInfoHeaderWidget(title: 'Thông tin nhập ngũ'),
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
                          controller.sinhvienEdit.value.isBoDoi =
                              !(controller.sinhvienEdit.value.isBoDoi ?? false);

                          if (controller.sinhvienEdit.value.isBoDoi == false) {
                            controller.sinhvienEdit.value.xuatNgu = null;
                            controller.sinhvienEdit.value.nhapNgu = null;
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Icon(
                            (controller.sinhvienEdit.value.isBoDoi ?? false)
                                ? Icons.check_box_rounded
                                : Icons
                                    .check_box_outline_blank_rounded, //check_box_outline_blank_rounded
                            color: const Color(0xff879ABF),
                          ),
                          spaceWidth(10),
                          Text('Đã đi bộ đội',
                              style: TextStyles.regular
                                  .copyWith(color: Colors.black))
                        ],
                      ),
                    ),
                  ),

                  VcoreProfileDatefieldWidget(
                    title: 'Ngày nhập ngũ',
                    hintText: 'Chọn ngày nhập ngũ',
                    value: (controller.sinhvienEdit.value.isBoDoi ?? false)
                        ? controller.sinhvienEdit.value.nhapNgu
                        : null,
                    onChangeDate: (selectedDate) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.nhapNgu = selectedDate;
                        },
                      );
                    },
                  ),
                  spaceHeight(itemSpace),

                  VcoreProfileDatefieldWidget(
                    title: 'Ngày xuất ngũ',
                    hintText: 'Chọn ngày xuất ngũ',
                    value: (controller.sinhvienEdit.value.isBoDoi ?? false)
                        ? controller.sinhvienEdit.value.xuatNgu
                        : null,
                    onChangeDate: (selectedDate) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.xuatNgu = selectedDate;
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
