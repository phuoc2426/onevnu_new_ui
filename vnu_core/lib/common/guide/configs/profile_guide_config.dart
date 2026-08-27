import 'package:flutter/material.dart';

import '../global/app_guide_module_ids.dart';
import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import '../registry/app_guide_global_registry.dart';
import 'app_guide_module_config.dart';

class ProfileGuideConfig implements AppGuideModuleConfig {
  const ProfileGuideConfig();

  static const String actionOpenProfileTab = 'app.open_profile_tab';
  static const String groupIntro = 'profile.intro';

  static Future<void> openProfileTab() async {
    await globalAppGuideRegistry.runAction(actionOpenProfileTab);
  }

  @override
  String get moduleId => AppGuideModuleIds.profile;

  @override
  List<AppGuideGroup> get groups => const [
        AppGuideGroup(
          id: groupIntro,
          moduleId: AppGuideModuleIds.profile,
          title: 'Hướng dẫn hồ sơ cá nhân',
          targetIds: [
            'profile.page',
            'profile.header',
            'profile.avatar',
            'profile.academic_summary',
            'profile.summary.semesters',
            'profile.summary.credits',
            'profile.summary.gpa',
            'profile.personal_info',
            'profile.family_info',
            'profile.change_avatar',
            'profile.bookmark',
            'profile.biometric',
            'profile.password',
            'profile.version',
            'profile.logout',
          ],
        ),
      ];

  @override
  List<AppGuideItem> get items => [
        _item(
          id: 'profile.page',
          type: AppGuideItemType.page,
          title: 'Hồ sơ cá nhân',
          description: 'Mở màn hồ sơ cá nhân của sinh viên.',
          icon: Icons.person_rounded,
          keywords: ['hồ sơ', 'profile', 'cá nhân'],
          priority: 1000,
          preferInSearch: true,
        ),
        _item(
          id: 'profile.header',
          type: AppGuideItemType.section,
          title: 'Thông tin hồ sơ',
          description: 'Khu vực đầu trang hồ sơ cá nhân.',
          icon: Icons.badge_rounded,
          keywords: ['hồ sơ', 'thông tin cá nhân'],
          priority: 950,
          fallbackId: 'profile.page',
        ),
        _item(
          id: 'profile.avatar',
          type: AppGuideItemType.widget,
          title: 'Ảnh đại diện',
          description: 'Ảnh đại diện hiện tại của sinh viên.',
          icon: Icons.account_circle_rounded,
          keywords: ['avatar', 'ảnh đại diện'],
          fallbackId: 'profile.header',
        ),
        _item(
          id: 'profile.academic_summary',
          type: AppGuideItemType.section,
          title: 'Tổng quan học tập',
          description: 'Tổng quan kỳ đã học, tín chỉ và điểm tích lũy.',
          icon: Icons.school_rounded,
          keywords: ['tín chỉ', 'điểm tích lũy', 'kỳ đã học'],
          fallbackId: 'profile.page',
        ),
        _item(
          id: 'profile.summary.semesters',
          type: AppGuideItemType.widget,
          title: 'Số kỳ đã học',
          description: 'Số học kỳ đã có dữ liệu học tập.',
          icon: Icons.calendar_month_rounded,
          keywords: ['học kỳ', 'kỳ đã học'],
          fallbackId: 'profile.academic_summary',
        ),
        _item(
          id: 'profile.summary.credits',
          type: AppGuideItemType.widget,
          title: 'Tín chỉ tích lũy',
          description: 'Tổng số tín chỉ đã tích lũy.',
          icon: Icons.workspace_premium_rounded,
          keywords: ['tín chỉ', 'tích lũy'],
          fallbackId: 'profile.academic_summary',
        ),
        _item(
          id: 'profile.summary.gpa',
          type: AppGuideItemType.widget,
          title: 'Điểm tích lũy',
          description: 'Điểm trung bình tích lũy hiện tại.',
          icon: Icons.grade_rounded,
          keywords: ['gpa', 'điểm tích lũy'],
          fallbackId: 'profile.academic_summary',
        ),
        _menuItem('profile.personal_info', 'Thông tin cá nhân', Icons.person_outline_rounded, ['thông tin cá nhân']),
        _menuItem('profile.family_info', 'Thông tin gia đình', Icons.family_restroom_rounded, ['gia đình']),
        _menuItem('profile.change_avatar', 'Đổi ảnh đại diện', Icons.photo_camera_rounded, ['đổi ảnh', 'avatar']),
        _menuItem('profile.bookmark', 'Liên kết đánh dấu', Icons.bookmark_rounded, ['đánh dấu', 'bookmark']),
        _menuItem('profile.biometric', 'Cài đặt sinh trắc học', Icons.fingerprint_rounded, ['sinh trắc học', 'vân tay', 'face id']),
        _menuItem('profile.password', 'Quản lý mật khẩu', Icons.lock_rounded, ['mật khẩu', 'đổi mật khẩu']),
        _menuItem('profile.version', 'Phiên bản ứng dụng', Icons.info_outline_rounded, ['phiên bản', 'version']),
        _menuItem('profile.logout', 'Đăng xuất', Icons.logout_rounded, ['đăng xuất', 'logout']),
      ];

  static AppGuideItem _menuItem(
    String id,
    String title,
    IconData icon,
    List<String> keywords,
  ) {
    return _item(
      id: id,
      type: AppGuideItemType.widget,
      title: title,
      description: 'Mục $title trong hồ sơ cá nhân.',
      icon: icon,
      keywords: keywords,
      fallbackId: 'profile.page',
    );
  }

  static AppGuideItem _item({
    required String id,
    required AppGuideItemType type,
    required String title,
    required String description,
    required IconData icon,
    required List<String> keywords,
    int priority = 500,
    bool preferInSearch = false,
    String? fallbackId,
  }) {
    return AppGuideItem(
      id: id,
      moduleId: AppGuideModuleIds.profile,
      groupId: groupIntro,
      pageId: 'profile',
      type: type,
      priority: priority,
      preferInSearch: preferInSearch,
      fallbackId: fallbackId,
      title: title,
      description: description,
      icon: icon,
      keywords: keywords,
      openAction: openProfileTab,
      beforeHighlightActionId: actionOpenProfileTab,
    );
  }
}
