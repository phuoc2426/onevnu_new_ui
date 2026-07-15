import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modules/notify/views/vcore_notify_view_v3.dart';

import '../global/app_guide_module_ids.dart';
import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import 'app_guide_module_config.dart';

class NotifyGuideConfig implements AppGuideModuleConfig {
  const NotifyGuideConfig();

  @override
  String get moduleId => AppGuideModuleIds.notify;

  @override
  List<AppGuideGroup> get groups => [
        AppGuideGroup(
                  id: 'notify.intro',
                  moduleId: AppGuideModuleIds.notify,
                  title: 'Hướng dẫn thông báo',
                  targetIds: [
                    'notify.page',
                    'notify.tabs',
                    'notify.list',
                  ],
                ),
      ];

  @override
  List<AppGuideItem> get items => [
        AppGuideItem(
              id: 'notify.page',
              moduleId: AppGuideModuleIds.notify,
              groupId: 'notify.intro',
              pageId: 'notify',
              type: AppGuideItemType.page,
              priority: 1000,
              preferInSearch: true,
              title: 'Thông báo',
              description: 'Mở màn danh sách thông báo.',
              icon: Icons.notifications_rounded,
              keywords: [
                'thông báo',
                'notification',
                'tin đào tạo',
                'tin hệ thống',
              ],
              openAction: () async {
                Get.to(() => const VcoreNotifyViewV3());
              },
            ),
        AppGuideItem(
              id: 'notify.tabs',
              moduleId: AppGuideModuleIds.notify,
              groupId: 'notify.intro',
              pageId: 'notify',
              type: AppGuideItemType.widget,
              priority: 800,
              fallbackId: 'notify.page',
              title: 'Tab thông báo',
              description: 'Chuyển giữa các nhóm thông báo.',
              icon: Icons.tab_rounded,
              keywords: [
                'tab thông báo',
                'tin hệ thống',
                'tin đào tạo',
              ],
              openAction: () async {
                Get.to(() => const VcoreNotifyViewV3());
              },
            ),
        AppGuideItem(
              id: 'notify.list',
              moduleId: AppGuideModuleIds.notify,
              groupId: 'notify.intro',
              pageId: 'notify',
              type: AppGuideItemType.widget,
              priority: 790,
              fallbackId: 'notify.page',
              title: 'Danh sách thông báo',
              description: 'Danh sách các thông báo mới nhất.',
              icon: Icons.list_alt_rounded,
              keywords: [
                'danh sách thông báo',
                'thông báo mới',
              ],
              openAction: () async {
                Get.to(() => const VcoreNotifyViewV3());
              },
            ),
      ];
}
