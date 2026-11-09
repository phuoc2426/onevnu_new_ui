import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';

import '../../controllers/vcore_profile_person_info_controller.dart';
import 'vcore_profile_dropdownfield_widget.dart';
import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonNoisinhWidget extends StatelessWidget {
  const VcoreProfilePersonNoisinhWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller = Get.find();

    const itemSpace = 16.0;
    return Obx(
      () => Container(
          color: Colors.white,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const VcoreProfileInfoHeaderWidget(title: 'Nơi sinh'),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // --- Lay tu thong tin truoc
                  InkWell(
                    onTap: () {
                      print('Copy info...');
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.idNoiSinhQuocGia = item.idQueQuanQuocGia;
                          //reset
                          item?.idNoiSinhTinhThanhPho =
                              item.idQueQuanTinhThanhPho;

                          controller.listQuanHuyenNoiSinh =
                              controller.listQuanHuyenQueQuan;
                          item?.idNoiSinhQuanHuyen = '';

                          item?.noiSinhPhuongXa = item.queQuanPhuongXa;
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
                            'Lấy thông tin theo quê quán',
                            style: TextStyles.regular
                                .copyWith(color: const Color(0xff466FFF)),
                          )
                        ],
                      ),
                    ),
                  ),

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
                                controller.sinhvienEdit.value.idNoiSinhQuocGia;
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
                                    .sinhvienEdit.value.idNoiSinhQuocGia ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idNoiSinhQuocGia = obj?.id;
                                //reset
                                item?.idNoiSinhTinhThanhPho = "";
                                item?.idNoiSinhQuanHuyen = "";
                                item?.noiSinhPhuongXa = "";
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
                                    .sinhvienEdit.value.idNoiSinhTinhThanhPho;
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
                                    .sinhvienEdit.value.idNoiSinhTinhThanhPho ==
                                obj?.id) {
                              return;
                            }
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.idNoiSinhTinhThanhPho = obj?.id;
                                //reset
                                item?.idNoiSinhQuanHuyen = "";
                                item?.noiSinhPhuongXa = "";
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
                      title: 'Xã/Phường/Đặc khu',
                      hintText: 'Nhập tên xã/phường/đặc khu',
                      value: controller.sinhvienEdit.value.noiSinhPhuongXa,
                      onChange: (text) {
                        controller.sinhvienEdit.update(
                          (item) {
                            item?.noiSinhPhuongXa = text;
                                item?.idNoiSinhQuanHuyen = '';
                          },
                        );
                      },
                      onSubmitted: (text) {},
                    )),
                  ]),
                ]))
          ])),
    );
  }
}

