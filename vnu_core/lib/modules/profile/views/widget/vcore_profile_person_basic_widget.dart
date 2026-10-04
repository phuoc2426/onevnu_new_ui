import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_dropdownfield_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_info_header_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import 'package:vnu_core/modules/profile/views/vcore_cccd_qr_scanner_view.dart';

import '../../controllers/vcore_profile_person_info_controller.dart';
import 'vcore_profile_datefield_widget.dart';

class VcoreProfilePersonBasicWidget extends StatelessWidget {
  const VcoreProfilePersonBasicWidget({
    super.key,
    this.cccdSectionKey,
  });

  final Key? cccdSectionKey;

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

                  KeyedSubtree(
                    key: cccdSectionKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        VcoreProfileTextFieldWidget(
                          title: 'Số căn cước công dân (CCCD)',
                          hintText: 'Quét QR thẻ CCCD để cập nhật',
                          value: controller.sinhvienEdit.value.soCmtCccd ?? '',
                          isDisable: true,
                          onSubmitted: (text) {},
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final CccdQrScanResult? result =
                                await Navigator.of(context)
                                    .push<CccdQrScanResult>(
                              MaterialPageRoute<CccdQrScanResult>(
                                builder: (_) => VcoreCccdQrScannerView(
                                  trainingStudentCode: Globals()
                                          .thongTinSinhVienModel
                                          .value
                                          ?.maSinhVien
                                          ?.trim() ??
                                      '',
                                  trainingFullName: Globals()
                                          .thongTinSinhVienModel
                                          .value
                                          ?.hoVaTen
                                          ?.trim() ??
                                      '',
                                  trainingDateOfBirth: Globals()
                                      .thongTinSinhVienModel
                                      .value
                                      ?.ngaySinh,
                                ),
                              ),
                            );
                            if (result == null) return;
                            controller.applyVerifiedCccdFromQr(
                              cccd: result.cccd,
                              fullName: result.fullName,
                              dateOfBirth: result.dateOfBirth,
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Quét QR thẻ CCCD'),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.amber.shade700.withOpacity(0.45),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.amber.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Không nhập CCCD bằng bàn phím. Hãy quét QR trên thẻ căn cước. '
                                  'Sau khi quét, dữ liệu chỉ ở trạng thái chờ xác nhận. '
                                  'Chỉ khi bạn bấm Cập nhật, hệ thống mới đối chiếu mã sinh viên, CCCD, họ tên và ngày sinh với dữ liệu đào tạo.',
                                  style: TextStyle(fontSize: 12.5, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  spaceHeight(itemSpace),
                  //Ngay cap - Noi cap
                  Row(children: [
                    //
                    Expanded(
                      child: VcoreProfileDatefieldWidget(
                        title: 'Ngày cấp',
                        hintText: 'Chọn ngày cấp',
                        value: controller.sinhvienEdit.value.ngayCapCmtCccd,
                        onChangeDate: (DateTime? value) {
                          controller.sinhvienEdit.update((item) {
                            item?.ngayCapCmtCccd = value;
                          });
                        },
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
                            controller
                                .sinhvienEdit.value.idNoiCapCmtCccdTinhThanhPho;
                      })?.ten,
                      items: controller.listTinhThanhPho.map((e) {
                        return e.ten ?? '';
                      }).toList(),
                      onSelected: (value) {
                        final obj = controller.listTinhThanhPho
                            .firstWhereOrNull((item) => item.ten == value);
                        controller.sinhvienEdit.update((item) {
                          item?.idNoiCapCmtCccdTinhThanhPho = obj?.id;
                        });
                      },
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
