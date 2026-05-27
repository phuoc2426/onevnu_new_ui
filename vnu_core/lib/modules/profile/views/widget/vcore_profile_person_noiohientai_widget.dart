import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';

import 'vcore_profile_dropdownfield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonNoiOHienTaiWidget extends StatelessWidget {
  const VcoreProfilePersonNoiOHienTaiWidget({super.key});

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
            const VcoreProfileInfoHeaderWidget(title: 'Nơi ở hiện nay'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.idNoiOHienNayTinhThanhPho =
                              item.idHoKhauThuongTruTinhThanhPho;

                          controller.listQuanHuyenNoiOHienNay =
                              controller.listQuanHuyenThuongTru;
                          item?.idNoiOHienNayQuanHuyen =
                              item.idHoKhauThuongTruQuanHuyen;

                          item?.noiOHienNayPhuongXa =
                              item.hoKhauThuongTruPhuongXa;
                          item?.noiOHienNayDuongThon =
                              item.hoKhauThuongTruDuongThon;
                          item?.noiOHienNaySoNha = item.hoKhauThuongTruSoNha;
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          svgAsset(
                              'assets/images/ic_profile_info_location.svg'),
                          spaceWidth(10),
                          Text(
                            'Lấy thông tin theo hộ khẩu',
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
                                      .idNoiOHienNayTinhThanhPho;
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
                                    .idNoiOHienNayTinhThanhPho ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idNoiOHienNayTinhThanhPho = obj?.id;
                                //reset
                                item?.idNoiOHienNayQuanHuyen = "";

                                controller.refreshQuanHuyenNoiOHienNay();
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
                          value: controller.listQuanHuyenNoiOHienNay
                              .firstWhereOrNull((item) {
                            return item.id ==
                                controller
                                    .sinhvienEdit.value.idNoiOHienNayQuanHuyen;
                          })?.ten,
                          items: controller.listQuanHuyenNoiOHienNay.map(
                            (e) {
                              return e.ten ?? '';
                            },
                          ).toList(),
                          onSelected: (value) {
                            var obj = controller.listQuanHuyenNoiOHienNay
                                .firstWhereOrNull((item) {
                              return item.ten == value;
                            });
                            if (controller.sinhvienEdit.value
                                    .idNoiOHienNayQuanHuyen ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idNoiOHienNayQuanHuyen = obj?.id;
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
                          value:
                              controller.sinhvienEdit.value.noiOHienNayPhuongXa,
                          onChange: (text) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.noiOHienNayPhuongXa = text;
                              },
                            );
                          },
                          onSubmitted: (text) {},
                        ),
                      ),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                          title: 'Đường/Thôn',
                          hintText: 'Nhập Đường/Thôn',
                          value: controller
                              .sinhvienEdit.value.noiOHienNayDuongThon,
                          onChange: (text) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.noiOHienNayDuongThon = text;
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
                    value: controller.sinhvienEdit.value.noiOHienNaySoNha,
                    onChange: (text) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.noiOHienNaySoNha = text;
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
