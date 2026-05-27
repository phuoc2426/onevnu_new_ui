import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';

import 'vcore_profile_dropdownfield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonDiaChiLienLacWidget extends StatelessWidget {
  const VcoreProfilePersonDiaChiLienLacWidget({super.key});

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
            const VcoreProfileInfoHeaderWidget(title: 'Địa chỉ liên lạc'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      print('Lấy theo thông tin Nơi ở hiện nay');
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.idDiaChiLienLacTinhThanhPho =
                              item.idNoiOHienNayTinhThanhPho;

                          controller.listQuanHuyenDiaChiLL =
                              controller.listQuanHuyenNoiOHienNay;
                          item?.idDiaChiLienLacQuanHuyen =
                              item.idNoiOHienNayQuanHuyen;

                          item?.diaChiLienLacPhuongXa =
                              item.noiOHienNayPhuongXa;
                          item?.diaChiLienLacDuongThon =
                              item.noiOHienNayDuongThon;
                          item?.diaChiLienLacSoNha = item.noiOHienNaySoNha;
                        },
                      );

                      controller.update();
                    },
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          svgAsset(
                              'assets/images/ic_profile_info_location.svg'),
                          spaceWidth(10),
                          Text(
                            'Lấy thông tin theo nơi ở',
                            style: TextStyles.regular
                                .copyWith(color: const Color(0xff466FFF)),
                          )
                        ],
                      ),
                    ),
                  ),

                  //Thành phố - tinh TP
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                          title: 'Tỉnh/Thành phố',
                          hintText: 'Chọn Tỉnh/TP',
                          value: controller.listTinhThanhPho.firstWhereOrNull(
                            (item) {
                              return item.id ==
                                  controller.sinhvienEdit.value
                                      .idDiaChiLienLacTinhThanhPho;
                            },
                          )?.ten,
                          items: controller.listTinhThanhPho.map(
                            (e) {
                              return e.ten ?? '';
                            },
                          ).toList(),
                          onSelected: (value) {
                            var obj =
                                controller.listTinhThanhPho.firstWhereOrNull(
                              (item) {
                                return item.ten == value;
                              },
                            );
                            if (controller.sinhvienEdit.value
                                    .idDiaChiLienLacTinhThanhPho ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idDiaChiLienLacTinhThanhPho = obj?.id;
                                //reset
                                item?.idDiaChiLienLacQuanHuyen = "";

                                controller.refreshQuanHuyenDiaChiLL();
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
                          value: controller.listQuanHuyenDiaChiLL
                              .firstWhereOrNull((item) {
                            return item.id ==
                                controller.sinhvienEdit.value
                                    .idDiaChiLienLacQuanHuyen;
                          })?.ten,
                          items: controller.listQuanHuyenDiaChiLL.map(
                            (e) {
                              return e.ten ?? '';
                            },
                          ).toList(),
                          onSelected: (value) {
                            var obj = controller.listQuanHuyenDiaChiLL
                                .firstWhereOrNull((item) {
                              return item.ten == value;
                            });
                            if (controller.sinhvienEdit.value
                                    .idDiaChiLienLacQuanHuyen ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idDiaChiLienLacQuanHuyen = obj?.id;
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
                        child: VcoreProfileTextFieldWidget(
                          title: 'Phường/Xã/Thị trấn',
                          hintText: 'Nhập P/X/TT',
                          value: controller
                              .sinhvienEdit.value.diaChiLienLacPhuongXa,
                          onChange: (text) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.diaChiLienLacPhuongXa = text;
                              },
                            );
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
                              .sinhvienEdit.value.diaChiLienLacDuongThon,
                          onChange: (text) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.diaChiLienLacDuongThon = text;
                              },
                            );
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
                    value: controller.sinhvienEdit.value.diaChiLienLacSoNha,
                    onChange: (text) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.diaChiLienLacSoNha = text;
                        },
                      );
                    },
                    onSubmitted: (text) {},
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
