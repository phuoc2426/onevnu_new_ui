import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/guide/guide.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/screens/vcore_admission_view.dart';
import 'package:vnu_core/modules/bookmark/views/vcore_bookmark_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_avatar_widget.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_change_pass_view_v2.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_family_info_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_person_info_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_setup_bio_view.dart';
import 'package:vnu_core/modules/shapeshifter/views/shapeshifter_my_features.dart';

import '../controllers/vcore_profile_controller.dart';
import 'vcore_profile_change_pass_view.dart';
// import 'vcore_profile_photos_view.dart';
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
        return AppGuideAnchor(
          id: 'profile.page',
          child: Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),
          body: Obx(
            () => SingleChildScrollView(
              child: Column(
                children: [
                  AppGuideAnchor(
                    id: 'profile.header',
                    child: SafeArea(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                            AppGuideAnchor(
                              id: 'profile.avatar',
                              child: GestureDetector(
                                onTap: controller.isChangingAvatar.value
                                    ? null
                                    : () {
                                        controller.pickAndPreviewAvatar(
                                          context,
                                        );
                                      },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Obx(
                                      () => AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: controller.isChangingAvatar.value
                                            ? Container(
                                                key: const ValueKey(
                                                  'avatar-loading',
                                                ),
                                                width: 76,
                                                height: 76,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFF1E293B,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              )
                                            : VcoreProfileAvatarWidget(
                                                key: ValueKey(
                                                  controller.avatarUrl,
                                                ),
                                                url: controller.avatarUrl,
                                                size: 76,
                                                showStatus: false,
                                              ),
                                      ),
                                    ),

                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (controller.tongket.value != null)
                    AppGuideAnchor(
                      id: 'profile.academic_summary',
                      child: Container(
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
                              guideId: 'profile.summary.semesters',
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
                              controller.tongket.value?.tongSoTinChiTichLuy ??
                                  '',
                              guideId: 'profile.summary.credits',
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
                              controller
                                      .tongket
                                      .value
                                      ?.diemTrungBinhHe4TichLuy ??
                                  '',
                              guideId: 'profile.summary.gpa',
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 16),

                  VcoreProfileItemWidget(
                    title: "Thông tin cá nhân",
                    guideId: 'profile.personal_info',
                    icon: 'assets/images/ic_profile_person.svg',
                    action: () {
                      Get.to(() => const VcoreProfilePersonInfoView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Thông tin gia đình",
                    guideId: 'profile.family_info',
                    icon: 'assets/images/ic_profile_family.svg',
                    action: () {
                      Get.to(() => const VcoreProfileFamilyInfoView());
                    },
                  ),
                  const SizedBox(height: 12),

                  // Dynamic services configured from ONEVNU Admin. The API already
                  // filters STUDENT vs admitted-student audiences and MY placement.
                  const ShapeshifterMyFeatures(
                    layout: ShapeshifterMyLayout.studentList,
                  ),

                  // VcoreProfileItemWidget(
                  //   title: "Quản lý ảnh cá nhân",
                  //   guideId: 'profile.photo_manager',
                  //   icon: 'assets/images/ic_profile_photo_manager.svg',
                  //   action: () {
                  //     Get.to(() => const VcoreProfilePhotosView());
                  //   },
                  // ),
                  // const SizedBox(height: 12),
                  VcoreProfileItemWidget(
                    title: "Đổi ảnh đại diện",
                    guideId: 'profile.change_avatar',
                    icon: 'assets/images/ic_profile_photo_manager.svg',
                    action: () {
                      controller.pickAndPreviewAvatar(context);
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Liên kết đánh dấu",
                    guideId: 'profile.bookmark',
                    icon: 'assets/images/ic_profile_bookmark.svg',
                    action: () {
                      Get.to(() => const VcoreBookmarkView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Cài đặt sinh trắc học",
                    guideId: 'profile.biometric',
                    icon: 'assets/images/ic_profile_setup_bio.svg',
                    action: () {
                      Get.to(() => const VcoreProfileSetupBioView());
                    },
                  ),
                  const SizedBox(height: 12),

                  VcoreProfileItemWidget(
                    title: "Quản lý mật khẩu",
                    guideId: 'profile.password',
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
                        guideId: 'profile.version',
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
                    guideId: 'profile.logout',
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
          ),
        );
      },
    );
  }

  Widget itemPointProfile(String title, String point, {String? guideId}) {
    final content = Column(
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

    if (guideId == null) return content;

    return AppGuideAnchor(id: guideId, child: content);
  }
}

class VcoreProfileItemWidget extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback action;
  final String? guideId;

  const VcoreProfileItemWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.action,
    this.guideId,
  });

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
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

    if (guideId == null) return content;

    return AppGuideAnchor(id: guideId!, child: content);
  }
}
