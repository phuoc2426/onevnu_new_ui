import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/admission/views/vcore_admission_view.dart';
import 'package:vnu_core/modules/bookmark/views/vcore_bookmark_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_avatar_widget.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_change_pass_view_v2.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_family_info_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_person_info_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_setup_bio_view.dart';

import '../controllers/vcore_profile_controller.dart';
import 'vcore_profile_change_pass_view.dart';
import 'vcore_profile_photos_view.dart';
import 'package:flutter/foundation.dart';

class VcoreProfileView extends GetView<VcoreProfileController> {
  const VcoreProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreProfileController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        controller.getTongKetDenHienTai();
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),
          body: Obx(
            () => SingleChildScrollView(
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Globals()
                                          .thongTinSinhVienModel
                                          .value
                                          ?.hoVaTen ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.large,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1e293b),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      "MSV: ",
                                      style: TextStyle(
                                        fontSize: AppFontSizes.mediumSmall,
                                        color: Color(0xff64748b),
                                      ),
                                    ),
                                    Text(
                                      Globals()
                                              .thongTinSinhVienModel
                                              .value
                                              ?.maSinhVien ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.mediumSmall,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff334155),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Lớp: ",
                                      style: TextStyle(
                                        fontSize: AppFontSizes.mediumSmall,
                                        color: Color(0xff64748b),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        Globals().lopDaoTaoModel.value?.ten ??
                                            '',
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.mediumSmall,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff334155),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const SizedBox(
                            width: 76,
                            height: 76,
                            child: VcoreProfileAvatarWidget(
                              url:
                                  'https://vnu.edu.vn/upload/2014/11/17202/image/Logo-VNU-1995.jpg',
                              size: 76,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (controller.tongket.value != null)
                    Container(
                      height: 64,
                      margin: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          itemPointProfile(
                            'Kỳ đã học',
                            '${controller.tongket.value?.soKyDaHoc ?? ''}',
                          ),
                          const Spacer(),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const Spacer(),
                          itemPointProfile(
                            'Tín chỉ tích luỹ',
                            controller.tongket.value?.tongSoTinChiTichLuy ?? '',
                          ),
                          const Spacer(),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const Spacer(),
                          itemPointProfile(
                            'Điểm tích luỹ',
                            controller.tongket.value?.diemTrungBinhHe4TichLuy ??
                                '',
                          ),
                          const Spacer(),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 16),

                  VcoreProfileItemWidget(
                    title: "Thông tin cá nhân",
                    icon: 'assets/images/ic_profile_person.svg',
                    action: () {
                      Get.to(() => const VcoreProfilePersonInfoView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Thông tin gia đình",
                    icon: 'assets/images/ic_profile_family.svg',
                    action: () {
                      Get.to(() => const VcoreProfileFamilyInfoView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Quản lý ảnh cá nhân",
                    icon: 'assets/images/ic_profile_photo_manager.svg',
                    action: () {
                      Get.to(() => const VcoreProfilePhotosView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Liên kết đánh dấu",
                    icon: 'assets/images/ic_profile_bookmark.svg',
                    action: () {
                      Get.to(() => const VcoreBookmarkView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Cài đặt sinh trắc học",
                    icon: 'assets/images/ic_profile_setup_bio.svg',
                    action: () {
                      Get.to(() => const VcoreProfileSetupBioView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Quản lý mật khẩu",
                    icon: 'assets/images/ic_password.svg',
                    action: () {
                      Get.to(() => const VcoreProfileChangePassViewV2());
                    },
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder(
                    future: Utils.version(),
                    builder: (context, snapshot) {
                      return VcoreProfileItemWidget(
                        title: "Phiên bản: ${snapshot.data ?? '1.0.0'}",
                        icon: 'assets/images/logo-vnu.png',
                        action: () {
                          if (kDebugMode) {
                            controller.countVersionOpenLog(context);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Đăng xuất",
                    icon: 'assets/images/ic_profile_logout.svg',
                    action: () {
                      Utils.showAlertDialog(
                        context,
                        "Đăng xuất",
                        "Bạn có chắc chắn muốn Đăng xuất",
                        okStr: "Xác nhận",
                        cancelStr: "Đóng",
                        withoutBinding: true,
                        callBackOK: () {
                          Globals().clearSession(deleteUserLogin: false);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VcoreAdmissionView(),
                            ),
                            (route) => false,
                          );
                        },
                      );
                    },
                  ),

                  SizedBox(height: floatingNavBottomPadding(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget itemPointProfile(String title, String point) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              point,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppFontSizes.large,
              ),
            ),
          ],
        ),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFDCFCE7),
            fontSize: AppFontSizes.small,
          ),
        ),
      ],
    );
  }
}

class VcoreProfileItemWidget extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback action;

  const VcoreProfileItemWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F3F5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        height: 52,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: icon.endsWith("svg")
                  ? svgAsset(icon, width: 22, height: 22)
                  : imageAsset(icon, width: 22, height: 22),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSizes.medium,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
