import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_dropdownfield_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_noi_tru/modules/boarding/controllers/nt_boarding_register_controller.dart';
import 'package:vnu_noi_tru/widgets/nt_register_payment_info.dart';

class NtBoadingRegisterView extends GetView<NtBoardingRegisterController> {
  const NtBoadingRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    const _itemSpace = 16.0;

    return GetBuilder(
        init: NtBoardingRegisterController(),
        tag: const Uuid().v4(),
        builder: (controller) {
          return ProgressHubWidget(
              contextComplete: (hubContext) {
                controller.context = hubContext;
              },
              child: Scaffold(
                appBar: NaviWidget(
                  titleStr: 'Đăng ký nội trú',
                  leftAction: const BackButton(),
                ),
                backgroundColor: AppColor.bgColor,
                body: Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Expanded(
                            child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // -- Thông tin liên hệ
                              Container(
                                color: Colors.white,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thông tin liên hệ',
                                      style: TextStyles.semiBold
                                          .copyWith(color: Colors.black),
                                    ),
                                    spaceHeight(_itemSpace),
                                    VcoreProfileTextFieldWidget(
                                        title: 'Email',
                                        hintText: 'Nhập email',
                                        value: '',
                                        isRequired: true,
                                        onSubmitted: (text) {}),
                                    spaceHeight(_itemSpace),
                                    VcoreProfileTextFieldWidget(
                                        title: 'Số điện thoại',
                                        hintText: 'Nhập số điện thoại',
                                        value: '',
                                        isRequired: true,
                                        onSubmitted: (text) {}),
                                    spaceHeight(_itemSpace),
                                    VcoreProfileTextFieldWidget(
                                        title: 'Địa chỉ liên hệ',
                                        hintText: 'Nhập địa chỉ liên hệ',
                                        value: '',
                                        isRequired: false,
                                        onSubmitted: (text) {}),
                                  ],
                                ),
                              ),
                              spaceHeight(10),

                              // -- Thông tin đối tượng ưu tiên
                              Container(
                                color: Colors.white,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thông tin đối tượng ưu tiên',
                                      style: TextStyles.semiBold
                                          .copyWith(color: Colors.black),
                                    ),
                                    spaceHeight(_itemSpace),
                                    VcoreProfileDropdownfieldWidget(
                                      title: 'Đối tượng ưu tiên',
                                      hintText: 'Chọn đối tượng',
                                      value: controller.doiTuongUuTien.value
                                          ?.tenDoiTuongUuTien,
                                      isRequired: true,
                                      items: controller.danhSachDoiTuongUuTien
                                          .map((e) => e.tenDoiTuongUuTien ?? '')
                                          .toList(),
                                      onSelected: (value) {
                                        controller
                                            .selectedDoiTuongUuTien(value);
                                      },
                                    ),
                                    spaceHeight(_itemSpace),
                                    InkWell(
                                      onTap: () {
                                        logWarning('File minh chung...');
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            'File minh chứng',
                                            style: TextStyles.italic,
                                          ),
                                          spaceWidth(10),
                                          svgAsset(
                                              'assets/images/ic_attach_file.svg',
                                              height: 16),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              spaceHeight(10),

                              // -- Thông tin ký túc xá
                              Container(
                                  color: Colors.white,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Thông tin ký túc xá',
                                          style: TextStyles.semiBold
                                              .copyWith(color: Colors.black),
                                        ),

                                        //
                                        spaceHeight(_itemSpace),
                                        VcoreProfileDropdownfieldWidget(
                                          title: 'Đợt đăng ký',
                                          hintText: 'Chọn đợt đăng ký',
                                          value: controller.dotDangKyLuuTru
                                              .value?.tenDotDangKy,
                                          isRequired: true,
                                          items: controller
                                              .danhSachDotDangKyLuuTru
                                              .map((e) => e.tenDotDangKy ?? '')
                                              .toList(),
                                          onSelected: (value) {
                                            controller.selectedDotDangKy(value);
                                          },
                                        ),

                                        //
                                        spaceHeight(_itemSpace),
                                        VcoreProfileDropdownfieldWidget(
                                          title: 'Ký túc xá',
                                          hintText: 'Chọn ký túc xá',
                                          value: controller.trungTamLuuTru.value
                                              ?.tenTrungTamLuuTru,
                                          isRequired: true,
                                          items: controller
                                              .danhSachTrungTamLuuTru
                                              .map((e) =>
                                                  e.tenTrungTamLuuTru ?? '')
                                              .toList(),
                                          onSelected: (value) {
                                            //
                                            controller.selectedKyTucXa(value);
                                          },
                                        ),

                                        //
                                        spaceHeight(_itemSpace),
                                        VcoreProfileDropdownfieldWidget(
                                          title: 'Loại phòng',
                                          hintText: 'Chọn loại phòng',
                                          value: controller
                                              .loaiPhong.value?.tenLoaiPhong,
                                          isRequired: true,
                                          items: controller.danhSachLoaiPhong
                                              .map((e) => e.tenLoaiPhong ?? '')
                                              .toList(),
                                          onSelected: (value) {
                                            //
                                            controller.selectedLoaiPhong(value);
                                          },
                                        ),
                                        spaceHeight(_itemSpace),
                                      ])),
                              spaceHeight(10),

                              // Loại phòng chi phí, vật tư
                              Visibility(
                                  visible: controller.loaiPhong.value != null,
                                  child: NTRegisterPaymentInfoWidget(
                                    loaiPhong: controller.loaiPhong.value,
                                  )),
                              spaceHeight(10)
                            ],
                          ),
                        )),

                        // --- Button action Save Submit
                        SafeArea(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: WhiteButton(
                                    title: 'Lưu',
                                    action: () {
                                      logWarning('TODO: - luuw');
                                    },
                                  ),
                                ),
                                spaceWidth(25),
                                Expanded(
                                  child: BlueButton(
                                    title: 'Gửi',
                                    action: () {
                                      logWarning('TODO: - guiwr');
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
        });
  }
}
