import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modules/course_points/views/vcore_course_points_view.dart';

import '../global/app_guide_module_ids.dart';
import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import 'app_guide_module_config.dart';

class CoursePointsGuideConfig implements AppGuideModuleConfig {
  const CoursePointsGuideConfig();

  @override
  String get moduleId => AppGuideModuleIds.coursePoints;

  @override
  List<AppGuideGroup> get groups => [
        AppGuideGroup(
                  id: 'course_points.intro',
                  moduleId: AppGuideModuleIds.coursePoints,
                  title: 'Hướng dẫn điểm học tập',
                  targetIds: [
                    'course_points.page',
                    'course_points.summary',
                    'course_points.radar_chart',
                    'course_points.list',
                  ],
                ),
      ];

  @override
  List<AppGuideItem> get items => [
        AppGuideItem(
              id: 'course_points.page',
              moduleId: AppGuideModuleIds.coursePoints,
              groupId: 'course_points.intro',
              pageId: 'course_points',
              type: AppGuideItemType.page,
              priority: 1000,
              preferInSearch: true,
              title: 'Điểm học tập',
              description: 'Mở màn điểm và kết quả học tập.',
              icon: Icons.grade_rounded,
              keywords: [
                'điểm',
                'bảng điểm',
                'gpa',
                'kết quả học tập',
              ],
              openAction: () async {
                Get.to(() => const VcoreCoursePointsView());
              },
            ),
        AppGuideItem(
              id: 'course_points.summary',
              moduleId: AppGuideModuleIds.coursePoints,
              groupId: 'course_points.intro',
              pageId: 'course_points',
              type: AppGuideItemType.widget,
              priority: 900,
              fallbackId: 'course_points.page',
              title: 'Tổng quan điểm',
              description: 'Khu vực tổng hợp số tín chỉ, điểm trung bình và tiến độ học tập.',
              icon: Icons.analytics_rounded,
              keywords: [
                'tổng quan điểm',
                'gpa',
                'tín chỉ',
                'điểm trung bình',
              ],
              openAction: () async {
                Get.to(() => const VcoreCoursePointsView());
              },
            ),
        AppGuideItem(
              id: 'course_points.radar_chart',
              moduleId: AppGuideModuleIds.coursePoints,
              groupId: 'course_points.intro',
              pageId: 'course_points',
              type: AppGuideItemType.widget,
              priority: 850,
              fallbackId: 'course_points.summary',
              title: 'Biểu đồ năng lực',
              description: 'Biểu đồ radar phân tích năng lực học tập theo các trục.',
              icon: Icons.radar_rounded,
              keywords: [
                'radar',
                'năng lực',
                'biểu đồ',
                'phân tích điểm',
              ],
              openAction: () async {
                Get.to(() => const VcoreCoursePointsView());
              },
            ),
        AppGuideItem(
              id: 'course_points.list',
              moduleId: AppGuideModuleIds.coursePoints,
              groupId: 'course_points.intro',
              pageId: 'course_points',
              type: AppGuideItemType.widget,
              priority: 800,
              fallbackId: 'course_points.page',
              title: 'Danh sách học phần',
              description: 'Danh sách điểm theo từng học phần.',
              icon: Icons.format_list_bulleted_rounded,
              keywords: [
                'danh sách điểm',
                'học phần',
                'điểm học phần',
              ],
              openAction: () async {
                Get.to(() => const VcoreCoursePointsView());
              },
            ),
      ];
}
