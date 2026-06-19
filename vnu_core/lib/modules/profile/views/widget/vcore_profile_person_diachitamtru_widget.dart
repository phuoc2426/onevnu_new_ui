import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';

import 'vcore_profile_dropdownfield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonDiaChiTamTruWidget extends StatelessWidget {
  const VcoreProfilePersonDiaChiTamTruWidget({super.key});

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
            const VcoreProfileInfoHeaderWidget(title: 'Địa chỉ tạm trú'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Thành phố - tinh TP
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Tỉnh/Thành phố',
                          hintText: 'Chọn Tỉnh/TP',
                          value: controller.listTinhThanhPho.firstWhereOrNull((
                            item,
                          ) {
                            return item.id ==
                                controller
                                    .sinhvienEdit
                                    .value
                                    .diaChiTamTruTinhThanhPho;
                          })?.ten,
                          items: controller.listTinhThanhPho.map((e) {
                            return e.ten ?? '';
                          }).toList(),
                          onSelected: (value) {
                            final obj = controller.listTinhThanhPho
                                .firstWhereOrNull((item) {
                                  return item.ten == value;
                                });

                            if (controller
                                    .sinhvienEdit
                                    .value
                                    .diaChiTamTruTinhThanhPho ==
                                obj?.id) {
                              return;
                            }

                            controller.sinhvienEdit.update((item) {
                              item?.diaChiTamTruTinhThanhPho = obj?.id;

                              // Khi đổi tỉnh/thành thì phải reset quận/huyện cũ
                              item?.diaChiTamTruQuanHuyen = "";
                            });

                            // Load lại danh sách quận/huyện theo tỉnh mới
                            controller.refreshQuanHuyenDiaChiTamTru();
                          },
                        ),
                      ),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Quận/Huyện',
                          hintText: 'Chọn Quận/Huyện',
                          value: controller.listQuanHuyenDiaChiTamTru
                              .firstWhereOrNull((item) {
                                return item.id ==
                                    controller
                                        .sinhvienEdit
                                        .value
                                        .diaChiTamTruQuanHuyen;
                              })
                              ?.ten,
                          items: controller.listQuanHuyenDiaChiTamTru.map((e) {
                            return e.ten ?? '';
                          }).toList(),
                          onSelected: (value) {
                            final obj = controller.listQuanHuyenDiaChiTamTru
                                .firstWhereOrNull((item) {
                                  return item.ten == value;
                                });

                            controller.sinhvienEdit.update((item) {
                              item?.diaChiTamTruQuanHuyen = obj?.id;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  spaceHeight(itemSpace),

                  //Quận/Huyện
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                          title: 'Phường/Xã/Thị trấn',
                          hintText: 'Nhập P/X/TT',
                          value: controller
                              .sinhvienEdit
                              .value
                              .diaChiTamTruPhuongXa,
                          onChange: (text) {
                            controller.sinhvienEdit.update((item) {
                              item?.diaChiTamTruPhuongXa = text;
                            });
                          },
                          onSubmitted: (text) {},
                        ),
                      ),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                          //key: Key(const Uuid().v4()),
                          title: 'Đường/Thôn',
                          hintText: 'Nhập Đường/Thôn',
                          value: controller
                              .sinhvienEdit
                              .value
                              .diaChiTamTruDuongThon,
                          onChange: (text) {
                            controller.sinhvienEdit.update((item) {
                              item?.diaChiTamTruDuongThon = text;
                            });
                          },
                          onSubmitted: (text) {},
                        ),
                      ),
                    ],
                  ),
                  spaceHeight(itemSpace),

                  VcoreProfileTextFieldWidget(
                    title: 'Số nhà/đội',
                    hintText: 'Nhập số nhà/đội',
                    value: controller.sinhvienEdit.value.diaChiTamTruSoNha,
                    onChange: (text) {
                      controller.sinhvienEdit.update((item) {
                        item?.diaChiTamTruSoNha = text;
                      });
                    },
                    onSubmitted: (text) {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
