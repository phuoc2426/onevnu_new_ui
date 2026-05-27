import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_dropdownfield_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_info_header_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';

import '../../controllers/vcore_profile_person_info_controller.dart';
import 'vcore_profile_datefield_widget.dart';

class VcoreProfilePersonBasicWidget extends StatelessWidget {
  const VcoreProfilePersonBasicWidget({super.key});

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
            const VcoreProfileInfoHeaderWidget(title: 'Thông tin cơ bản'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // VcoreProfileTextFieldWidget(
                  //     title: 'Tên tiếng Anh (nếu có)',
                  //     hintText: 'Nhập tên tiếng Anh',
                  //     value: '',
                  //     onSubmitted: (text) {}),
                  // spaceHeight(itemSpace),
                  //
                  VcoreProfileTextFieldWidget(
                    title: 'Tên gọi khác',
                    hintText: 'Nhập tên gọi khác',
                    value: controller.sinhvienEdit.value.tenKhac ?? '',
                    onChange: (text) {
                      controller.sinhvienEdit.update(
                        (item) {
                          item?.tenKhac = text;
                        },
                      );
                    },
                    onSubmitted: (text) {},
                  ),
                  spaceHeight(itemSpace),

                  //Quoc tich - Dan toc
                  Row(children: [
                    //
                    Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                      title: 'Quốc tịch',
                      hintText: 'Chọn Quốc tịch',
                      value: controller.listQuocGia.firstWhereOrNull((item) {
                        return item.id ==
                            controller.sinhvienEdit.value.idQuocGia;
                      })?.ten,
                      items: controller.listQuocGia.map((e) {
                        return e.ten ?? '';
                      }).toList(),
                      onSelected: (value) {
                        var obj =
                            controller.listQuocGia.firstWhereOrNull((item) {
                          return item.ten == value;
                        });
                        controller.sinhvienEdit.update(
                          (item) {
                            item?.idQuocGia = obj?.id;
                          },
                        );
                      },
                    )),
                    spaceWidth(10),
                    Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                      title: 'Dân tộc',
                      hintText: 'Chọn Dân tộc',
                      value: controller.listDanToc.firstWhereOrNull((item) {
                        return item.id ==
                            controller.sinhvienEdit.value.idDanToc;
                      })?.ten,
                      items: controller.listDanToc.map((e) {
                        return e.ten ?? '';
                      }).toList(),
                      onSelected: (value) {},
                    )),
                  ]),
                  spaceHeight(itemSpace),

                  //Quoc tich - Dan toc
                  Row(
                    children: [
                      //
                      Expanded(
                          child: VcoreProfileDropdownfieldWidget(
                        title: 'Tôn giáo',
                        hintText: 'Chọn tôn giáo',
                        value: controller.listTonGiao.firstWhereOrNull((item) {
                          return item.id ==
                              controller.sinhvienEdit.value.idTonGiao;
                        })?.ten,
                        items: controller.listTonGiao.map((e) {
                          return e.ten ?? '';
                        }).toList(),
                        onSelected: (value) {
                          var obj =
                              controller.listTonGiao.firstWhereOrNull((item) {
                            return item.ten == value;
                          });
                          controller.sinhvienEdit.update(
                            (item) {
                              item?.idTonGiao = obj?.id;
                              logWarning(
                                  'Change ton giao: --> ${item?.idTonGiao}');
                            },
                          );
                        },
                      )),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                          title: 'Nhóm máu',
                          hintText: 'nhóm máu',
                          value: controller.sinhvienEdit.value.nhomMau ?? '',
                          onChange: (text) {
                            controller.sinhvienEdit.update(
                              (item) {
                                item?.nhomMau = text;
                              },
                            );
                          },
                          onSubmitted: (text) {},
                        ),
                      ),
                    ],
                  ),
                  spaceHeight(itemSpace),

                  //Chieu cao can nang
                  Row(
                    children: [
                      //
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                            title: 'Chiều cao (cm)',
                            hintText: 'Nhập chiều cao',
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            value: controller.sinhvienEdit.value.chieuCao
                                .toString(),
                            onChange: (text) {
                              if (text.isEmpty) {
                                return;
                              }
                              controller.sinhvienEdit.update(
                                (item) {
                                  String newText = text.replaceAll(',', '.');
                                  print(double.parse(newText));
                                  item?.chieuCao = double.parse(newText);
                                },
                              );
                            },
                            onSubmitted: (text) {}),
                      ),
                      spaceWidth(10),
                      Expanded(
                        child: VcoreProfileTextFieldWidget(
                            title: 'Cân nặng (kg)',
                            hintText: 'Nhập cân nặng',
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            value: controller.sinhvienEdit.value.canNang
                                .toString(),
                            onChange: (text) {
                              if (text.isEmpty) {
                                return;
                              }
                              controller.sinhvienEdit.update(
                                (item) {
                                  String newText = text.replaceAll(',', '.');
                                  print(double.parse(newText));
                                  item?.canNang = double.parse(newText);
                                },
                              );
                            },
                            onSubmitted: (text) {}),
                      )
                    ],
                  ),
                  spaceHeight(itemSpace),
                  // --

                  VcoreProfileTextFieldWidget(
                    title: 'Số chứng minh thư / Căn cước công dân',
                    hintText: 'Nhập số CMT/CCCD',
                    keyboardType: TextInputType.number,
                    value:
                        Globals().thongTinSinhVienModel.value?.soCmtCccd ?? '',
                    isDisable: true,
                    onChange: (text) {},
                    onSubmitted: (text) {},
                  ),
                  spaceHeight(itemSpace),
                  //Ngay cap - Noi cap
                  Row(children: [
                    //
                    Expanded(
                      child: VcoreProfileDatefieldWidget(
                        title: 'Ngày cấp',
                        hintText: 'Chọn ngày cấp',
                        isDisable: true,
                        value: Globals()
                            .thongTinSinhVienModel
                            .value
                            ?.ngayCapCmtCccd,
                      ),
                    ),
                    spaceWidth(10),
                    Expanded(
                        child: VcoreProfileDropdownfieldWidget(
                      title: 'Nơi cấp',
                      hintText: 'Nơi cấp',
                      value:
                          controller.listTinhThanhPho.firstWhereOrNull((item) {
                        return item.id ==
                            Globals()
                                .thongTinSinhVienModel
                                .value
                                ?.idNoiCapCmtCccdTinhThanhPho;
                      })?.ten,
                      items: controller.listTinhThanhPho.map((e) {
                        return e.ten ?? '';
                      }).toList(),
                      onSelected: (value) {},
                    )),
                  ]),
                  spaceHeight(itemSpace),

                  // -- Doi tuong chinh sach
                  VcoreProfileDropdownfieldWidget(
                    title: 'Đối tượng chính sách',
                    hintText: 'Đối tượng chính sách',
                    value: controller.listKhuVucUuTien.firstWhereOrNull((item) {
                      return item.id ==
                          controller.sinhvienEdit.value.idDoiTuongUuTien;
                    })?.ten,
                    items: controller.listKhuVucUuTien.map((e) {
                      return e.ten ?? '';
                    }).toList(),
                    onSelected: (value) {},
                  ),
                  spaceHeight(itemSpace),

                  // ----
                  VcoreProfileTextFieldWidget(
                      title: 'Sở trường và năng khiếu',
                      hintText: 'Nhập sở trường và năng khiếu',
                      value: controller.sinhvienEdit.value.nangKhieu ?? '',
                      onChange: (text) {
                        controller.sinhvienEdit.update(
                          (item) {
                            item?.nangKhieu = text;
                          },
                        );
                      },
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
