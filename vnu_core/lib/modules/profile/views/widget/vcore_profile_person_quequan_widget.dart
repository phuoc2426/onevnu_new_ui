import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';
import 'vcore_profile_dropdownfield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonQuequanWidget extends StatelessWidget {
  const VcoreProfilePersonQuequanWidget({super.key});

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
            const VcoreProfileInfoHeaderWidget(title: 'Quê quán'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Quốc gia - tinh TP
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Quốc gia',
                          hintText: 'Chọn Quốc gia',
                          value:
                              controller.listQuocGia.firstWhereOrNull((item) {
                            return item.id ==
                                controller.sinhvienEdit.value.idQueQuanQuocGia;
                          })?.ten,
                          items: controller.listQuocGia.map((e) {
                            return e.ten ?? '';
                          }).toList(),
                          onSelected: (value) {
                            var obj =
                                controller.listQuocGia.firstWhereOrNull((item) {
                              return item.ten == value;
                            });
                            if (controller
                                    .sinhvienEdit.value.idQueQuanQuocGia ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idQueQuanQuocGia = obj?.id;
                                //reset
                                item?.idQueQuanTinhThanhPho = "";
                                item?.idQueQuanQuanHuyen = "";
                              },
                            );
                          },
                        ),
                      ),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Tỉnh/Thành phố',
                          hintText: 'Chọn Tỉnh/TP',
                          value: controller.listTinhThanhPho
                              .firstWhereOrNull((item) {
                            return item.id ==
                                controller
                                    .sinhvienEdit.value.idQueQuanTinhThanhPho;
                          })?.ten,
                          items: controller.listTinhThanhPho.map(
                            (e) {
                              return e.ten ?? '';
                            },
                          ).toList(),
                          onSelected: (value) {
                            var obj = controller.listTinhThanhPho
                                .firstWhereOrNull((item) {
                              return item.ten == value;
                            });
                            if (controller
                                    .sinhvienEdit.value.idQueQuanTinhThanhPho ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idQueQuanTinhThanhPho = obj?.id;
                                //reset
                                item?.idQueQuanQuanHuyen = "";

                                controller.refreshQuanHuyenQueQuan();
                              },
                            );
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
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Quận/Huyện',
                          hintText: 'Chọn Quận/Huyện',
                          value: controller.listQuanHuyenQueQuan
                              .firstWhereOrNull((item) {
                            return item.id ==
                                controller
                                    .sinhvienEdit.value.idQueQuanQuanHuyen;
                          })?.ten,
                          items: controller.listQuanHuyenQueQuan.map(
                            (e) {
                              return e.ten ?? '';
                            },
                          ).toList(),
                          onSelected: (value) {
                            var obj = controller.listQuanHuyenQueQuan
                                .firstWhereOrNull((item) {
                              return item.ten == value;
                            });
                            if (controller
                                    .sinhvienEdit.value.idQueQuanQuanHuyen ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idQueQuanQuanHuyen = obj?.id;
                              },
                            );
                          },
                        ),
                      ),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                          title: 'Phường/Xã/Thị trấn',
                          hintText: 'Nhập P/X/TT',
                          value: controller.sinhvienEdit.value.queQuanPhuongXa,
                          onChange: (text) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.queQuanPhuongXa = text;
                              },
                            );
                          },
                          onSubmitted: (text) {},
                        ),
                      ),
                    ],
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
