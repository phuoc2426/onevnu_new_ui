import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';

abstract class AppGuideModuleConfig {
  String get moduleId;

  List<AppGuideItem> get items;

  List<AppGuideGroup> get groups;
}
