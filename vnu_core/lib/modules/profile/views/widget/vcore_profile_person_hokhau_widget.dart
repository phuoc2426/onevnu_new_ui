import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';

import 'vcore_profile_dropdownfield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonHokhauWidget extends StatelessWidget {
  const VcoreProfilePersonHokhauWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller = Get.find();

    const itemSpace = 16.0;
    return Obx(
      () => Container(
          color: Colors.white,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const VcoreProfileInfoHeaderWidget(title: 'Hộ khẩu thường trú'),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  //Quốc gia - tinh TP
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Tỉnh/Thành phố',
                          hintText: 'Chọn Tỉnh/TP',
                          value: controller.listTinhThanhPho
                              .firstWhereOrNull((item) {
                            return item.id ==
                                controller.sinhvienEdit.value
                                    .idHoKhauThuongTruTinhThanhPho;
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
                            if (controller.sinhvienEdit.value
                                    .idHoKhauThuongTruTinhThanhPho ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idHoKhauThuongTruTinhThanhPho = obj?.id;
                                //reset
                                item?.idHoKhauThuongTruQuanHuyen = "";

                                controller.refreshQuanHuyenHoKhauThuongTru();
                              },
                            );
                          },
                        ),
                      ),
                      spaceWidth(10),

                      Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Quận/Huyện',
                          hintText: 'Chọn Quận/Huyện',
                          value: controller.listQuanHuyenThuongTru
                              .firstWhereOrNull((item) {
                            return item.id ==
                                controller.sinhvienEdit.value
                                    .idHoKhauThuongTruQuanHuyen;
                          })?.ten,
                          items: controller.listQuanHuyenThuongTru.map(
                            (e) {
                              return e.ten ?? '';
                            },
                          ).toList(),
                          onSelected: (value) {
                            var obj = controller.listQuanHuyenThuongTru
                                .firstWhereOrNull((item) {
                              return item.ten == value;
                            });
                            if (controller.sinhvienEdit.value
                                    .idHoKhauThuongTruQuanHuyen ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idHoKhauThuongTruQuanHuyen = obj?.id;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  spaceHeight(itemSpace),

                  //Quận/Huyện
                  Row(children: [
                    //
                    Expanded(
                        child: VcoreProfileTextFieldWidget(
                      title: 'Phường/Xã/Thị trấn',
                      hintText: 'Nhập P/X/TT',
                      value:
                          controller.sinhvienEdit.value.hoKhauThuongTruPhuongXa,
                      onChange: (text) {
                        controller.sinhvienEdit.update(
                          (item) {
                            item?.hoKhauThuongTruPhuongXa = text;
                          },
                        );
                      },
                      onSubmitted: (text) {},
                    )),
                    spaceWidth(10),
                    Expanded(
                        child: VcoreProfileTextFieldWidget(
                      title: 'Đường/Thôn',
                      hintText: 'Nhập Đường/Thôn',
                      value: controller
                          .sinhvienEdit.value.hoKhauThuongTruDuongThon,
                      onChange: (text) {
                        controller.sinhvienEdit.update(
                          (item) {
                            item?.hoKhauThuongTruDuongThon = text;
                          },
                        );
                      },
                      onSubmitted: (text) {},
                    )),
                  ]),
                  spaceHeight(itemSpace),

                  VcoreProfileTextFieldWidget(
                    title: 'Số nhà/đội',
                    hintText: 'Nhập số nhà/đội',
                    value: controller.sinhvienEdit.value.hoKhauThuongTruSoNha,
                    onChange: (text) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.hoKhauThuongTruSoNha = text;
                        },
                      );
                    },
                    onSubmitted: (text) {},
                  )
                ]))
          ])),
    );
  }
}
