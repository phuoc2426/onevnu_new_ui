import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';

import 'vcore_profile_datefield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonDangVienWidget extends StatelessWidget {
  const VcoreProfilePersonDangVienWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const itemSpace = 16.0;
    final VcoreProfilePersonInfoController controller = Get.find();

    return Obx(
      () => Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VcoreProfileInfoHeaderWidget(title: 'Thông tin Đảng'),
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
                          controller.sinhvienEdit.value.isDang =
                              !(controller.sinhvienEdit.value.isDang ?? false);

                          if (controller.sinhvienEdit.value.isDang == false) {
                            controller.sinhvienEdit.value.ngayVaoDang = null;
                            controller.sinhvienEdit.value.ngayVaoDangChinhThuc =
                                null;
                            controller.sinhvienEdit.value.noiVaoDang = "";
                            controller.sinhvienEdit.value.viTriCaoNhatDang = "";
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Icon(
                            (controller.sinhvienEdit.value.isDang ?? false)
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: const Color(0xff879ABF),
                          ),
                          spaceWidth(10),
                          Text('Là Đảng viên',
                              style: TextStyles.regular
                                  .copyWith(color: Colors.black))
                        ],
                      ),
                    ),
                  ),

                  //Ngày vào đảng
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileDatefieldWidget(
                          title: 'Ngày vào Đảng',
                          hintText: 'Chọn ngày',
                          value: controller.sinhvienEdit.value.ngayVaoDang,
                          onChangeDate: (selectedDate) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.ngayVaoDang = selectedDate;
                              },
                            );
                          },
                        ),
                      ),
                      spaceWidth(10),

                      Expanded(
                        child: VcoreProfileDatefieldWidget(
                          title: 'Ngày chính thức',
                          hintText: 'Chọn ngày',
                          value: controller
                              .sinhvienEdit.value.ngayVaoDangChinhThuc,
                          onChangeDate: (selectedDate) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.ngayVaoDangChinhThuc = selectedDate;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  spaceHeight(itemSpace),

                  VcoreProfileTextFieldWidget(
                    title: 'Nơi vào Đảng',
                    hintText: 'Nhập nơi vào Đảng',
                    value: controller.sinhvienEdit.value.noiVaoDang,
                    onChange: (text) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.noiVaoDang = text;
                        },
                      );
                    },
                    onSubmitted: (text) {},
                  ),
                  spaceHeight(itemSpace),

                  VcoreProfileTextFieldWidget(
                    title: 'Chức vụ Đảng cao nhất',
                    hintText: 'Nhập chức vụ Đảng cao nhất',
                    value: controller.sinhvienEdit.value.viTriCaoNhatDang,
                    onChange: (text) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.viTriCaoNhatDang = text;
                        },
                      );
                    },
                    onSubmitted: (text) {},
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
