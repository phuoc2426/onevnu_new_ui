import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../registry/app_guide_global_registry.dart';
import '../../../modules/profile/views/vcore_profile_view.dart';
import '../global/app_guide_module_ids.dart';
import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import 'app_guide_module_config.dart';

class ProfileGuideConfig implements AppGuideModuleConfig {
  const ProfileGuideConfig();

  static const String actionOpenProfileTab = 'app.open_profile_tab';

  static Future<void> openProfileTab() async {
    await globalAppGuideRegistry.runAction(actionOpenProfileTab);
  }
  static const groupIntro = 'profile.intro';

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
            'profile.personal_info',
            'profile.family_info',
            'profile.photo_manager',
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
      ];

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