import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modules/exam_schedule/views/vcore_exam_schedule_view.dart';

import '../global/app_guide_module_ids.dart';
import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import 'app_guide_module_config.dart';

class ExamScheduleGuideConfig implements AppGuideModuleConfig {
  const ExamScheduleGuideConfig();

  @override
  String get moduleId => AppGuideModuleIds.examSchedule;

  @override
  List<AppGuideGroup> get groups => [
        AppGuideGroup(
                  id: 'exam_schedule.intro',
                  moduleId: AppGuideModuleIds.examSchedule,
                  title: 'Hướng dẫn lịch học và lịch thi',
                  targetIds: [
                    'exam_schedule.page',
                    'exam_schedule.calendar',
                    'exam_schedule.list',
                  ],
                ),
      ];

  @override
  List<AppGuideItem> get items => [
        AppGuideItem(
              id: 'exam_schedule.page',
              moduleId: AppGuideModuleIds.examSchedule,
              groupId: 'exam_schedule.intro',
              pageId: 'exam_schedule',
              type: AppGuideItemType.page,
              priority: 1000,
              preferInSearch: true,
              title: 'Lịch học và lịch thi',
              description: 'Mở màn lịch học và lịch thi chi tiết.',
              icon: Icons.calendar_month_rounded,
              keywords: [
                'lịch học',
                'lịch thi',
                'thời khóa biểu',
                'ca thi',
              ],
              openAction: () async {
                Get.to(() => const VcoreExamScheduleView());
              },
            ),
        AppGuideItem(
              id: 'exam_schedule.calendar',
              moduleId: AppGuideModuleIds.examSchedule,
              groupId: 'exam_schedule.intro',
              pageId: 'exam_schedule',
              type: AppGuideItemType.widget,
              priority: 600,
              fallbackId: 'exam_schedule.page',
              title: 'Lịch theo ngày',
              description: 'Khu vực chọn ngày để xem lịch học và lịch thi.',
              icon: Icons.calendar_today_rounded,
              keywords: [
                'lịch',
                'ngày',
                'calendar',
              ],
              openAction: () async {
                Get.to(() => const VcoreExamScheduleView());
              },
            ),
        AppGuideItem(
              id: 'exam_schedule.list',
              moduleId: AppGuideModuleIds.examSchedule,
              groupId: 'exam_schedule.intro',
              pageId: 'exam_schedule',
              type: AppGuideItemType.widget,
              priority: 590,
              fallbackId: 'exam_schedule.page',
              title: 'Danh sách lịch',
              description: 'Danh sách lịch học và lịch thi trong ngày.',
              icon: Icons.list_alt_rounded,
              keywords: [
                'danh sách lịch',
                'lịch học',
                'lịch thi',
              ],
              openAction: () async {
                Get.to(() => const VcoreExamScheduleView());
              },
            ),
      ];
}
