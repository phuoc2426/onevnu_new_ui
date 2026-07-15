import '../configs/app_guide_module_config.dart';
import '../configs/course_points_guide_config.dart';
import '../configs/exam_schedule_guide_config.dart';
import '../configs/home_guide_config.dart';
import '../configs/notify_guide_config.dart';
import '../configs/profile_guide_config.dart';
import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';

class AppGuideCatalog {
  const AppGuideCatalog._();

  static final List<AppGuideModuleConfig> modules = [
    const HomeGuideConfig(),
    const CoursePointsGuideConfig(),
    const ExamScheduleGuideConfig(),
    const NotifyGuideConfig(),
    const ProfileGuideConfig(),
  ];

  static List<AppGuideItem> get items {
    return modules.expand((module) => module.items).toList(growable: false);
  }

  static List<AppGuideGroup> get groups {
    return modules.expand((module) => module.groups).toList(growable: false);
  }
}
