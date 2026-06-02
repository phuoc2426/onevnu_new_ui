import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_noi_tru/modules/boarding/controllers/nt_boarding_detail_controller.dart';
import 'package:vnu_noi_tru/screens/nt_register_process_screen.dart';
import 'package:vnu_noi_tru/widgets/nt_register_payment_info.dart';

class NtBoardingDetailView extends GetView<NtBoardingDetailController> {
  const NtBoardingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    const itemInfoSpace = 14.0;

    return GetBuilder(
      init: NtBoardingDetailController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Scaffold(
          appBar: NaviWidget(
            titleStr: 'Phiếu đăng ký nội trú',
          ),
          backgroundColor: AppColor.bgColor,
          body: ProgressHubWidget(
            contextComplete: (hubContext) {
              controller.context = hubContext;
            },
            child: SingleChildScrollView(
              child: Obx(
                () => Column(
                  children: [
                    // Trang thai
                    GestureDetector(
                      // Xem quá trình xử lý
                      onTap: () {
                        if (controller.phieuDangKyNoiTruModel?.id == null)
                          return;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => NTRegisterProcessScreen(
                                      maYeuCau: controller
                                          .phieuDangKyNoiTruModel!.id!,
                                    )));
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        color: Colors.white,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                svgAsset('assets/images/ic_status.svg'),
                                spaceWidth(10),
                                Text(
                                  'Trạng thái: ',
                                  style: TextStyles.regular,
                                ),
                                spaceWidth(itemInfoSpace),
                                Text(
                                  'Đã phê duyệt',
                                  style: TextStyles.semiBold.copyWith(
                                      color:
                                          Color(0xff466FFF)), //Từ chối - ED1F29
                                ),
                              ],
                            ),
                            spaceHeight(12),
                            _detailStatus(
                                'Phòng:', 'Phòng 401 - Tòa nhà KTX A1'),
                          ],
                        ),
                      ),
                    ),

                    // Thong tin lien he
                    spaceHeight(15),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      color: Colors.white,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin liên hệ',
                              style: TextStyles.semiBold
                                  .copyWith(color: Colors.black),
                            ),
                            spaceHeight(itemInfoSpace),
                            _itemInfo('Email:', 'nguyenvannam@gmail.com'),
                            spaceHeight(itemInfoSpace),
                            _itemInfo('Số điện thoại:', '0932891732'),
                            spaceHeight(itemInfoSpace),
                            _itemInfo('Địa chỉ liên hệ:',
                                'Số 5, Yên Hòa, Cầu Giấy, Hà Nội'),
                          ]),
                    ),

                    // Thong tin lien he
                    spaceHeight(15),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      color: Colors.white,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin đối tượng ưu tiên',
                              style: TextStyles.semiBold
                                  .copyWith(color: Colors.black),
                            ),
                            spaceHeight(itemInfoSpace),
                            _itemInfo(
                                'Đối tượng ưu tiên:', 'Đối tượng ưu tiên A'),
                            spaceHeight(itemInfoSpace),
                            InkWell(
                              onTap: () {
                                logWarning("Preview file....");
                              },
                              child: Text(
                                'Đối tượng ưu tiên cá nhân.pdf',
                                style: TextStyles.italic
                                    .copyWith(color: const Color(0xff0E91BD)),
                              ),
                            )
                          ]),
                    ),

                    spaceHeight(15),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      color: Colors.white,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin ký túc xá',
                              style: TextStyles.semiBold
                                  .copyWith(color: Colors.black),
                            ),
                            spaceHeight(itemInfoSpace),
                            _itemInfo('Đợt đăng ký:', 'Đợt đăng ký số 1'),
                            spaceHeight(itemInfoSpace),
                            _itemInfo('Ký túc xá:', 'Ký túc xá Mễ Trì'),
                            spaceHeight(itemInfoSpace),
                            _itemInfo(
                                'Loại phòng:', 'Loại phòng đầy đủ thiết bị'),
                          ]),
                    ),

                    Visibility(
                        visible: controller.loaiPhong.value != null,
                        child: NTRegisterPaymentInfoWidget(
                          loaiPhong: controller.loaiPhong.value,
                        ))
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailStatus(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        spaceWidth(27),
        Text(
          title,
          style: TextStyles.regular
              .copyWith(fontSize: AppFontSizes.mediumSmall, color: const Color(0xff637392)),
        ),
        spaceWidth(10),
        Flexible(
          child: Text(
            content,
            style: TextStyles.regular.copyWith(fontSize: AppFontSizes.mediumSmall),
          ),
        )
      ],
    );
  }

  Widget _itemInfo(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 126,
          child: Text(
            title,
            style: TextStyles.regular
                .copyWith(fontSize: AppFontSizes.small, color: const Color(0xff637392)),
          ),
        ),
        spaceWidth(10),
        Flexible(
          child: Text(
            content,
            style: TextStyles.semiBold.copyWith(fontSize: AppFontSizes.mediumSmall),
          ),
        )
      ],
    );
  }
}
