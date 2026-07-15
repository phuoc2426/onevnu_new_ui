import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import 'app_guide_item_type.dart';

class AppGuideItem {
  const AppGuideItem({
    required this.id,
    required this.moduleId,
    required this.groupId,
    required this.pageId,
    required this.title,
    required this.description,
    required this.icon,
    required this.keywords,
    this.type = AppGuideItemType.widget,
    this.priority = 0,
    this.preferInSearch = false,
    this.fallbackId,
    this.beforeHighlightActionId,
    this.searchableExtra = const [],
    this.openAction,
    this.beforeHighlight,
    this.targetBorderRadius,
    this.targetPadding,
    this.tooltipPosition,
  });

  final String id;
  final String moduleId;
  final String groupId;
  final String pageId;
  final String title;
  final String description;
  final IconData icon;
  final List<String> keywords;

  /// page/function: ưu tiên trong search và có thể mở sang màn khác.
  /// section/widget: ưu tiên highlight khu vực đang render.
  final AppGuideItemType type;

  /// Dùng để đẩy kết quả quan trọng lên cao hơn trong tìm kiếm.
  final int priority;

  /// Nếu true, item này được ưu tiên hiển thị trong nhóm "Đi tới chức năng".
  final bool preferInSearch;

  /// Nếu widget chi tiết chưa render, highlight widget cha/cụm cha.
  /// Ví dụ: home.schedule.next_exam -> fallback home.schedule.
  final String? fallbackId;

  /// Tên action đã đăng ký trong AppGuideRegistry.
  /// Dùng cho các thao tác runtime như đổi tab trong Home trước khi highlight.
  final String? beforeHighlightActionId;

  final List<String> searchableExtra;
  final Future<void> Function()? openAction;

  /// Callback tĩnh. Chỉ dùng khi không cần State của view.
  /// Nếu cần setState/chuyển tab trong view, dùng beforeHighlightActionId.
  final Future<void> Function()? beforeHighlight;

  final BorderRadius? targetBorderRadius;
  final EdgeInsets? targetPadding;
  final TooltipPosition? tooltipPosition;

  bool get isNavigationItem {
    return type == AppGuideItemType.page || type == AppGuideItemType.function;
  }

  bool get isSectionItem => type == AppGuideItemType.section;

  bool get isWidgetItem => type == AppGuideItemType.widget;

  String get searchableText {
    return [
      title,
      description,
      ...keywords,
      ...searchableExtra,
      moduleId,
      pageId,
      type.name,
    ].join(' ');
  }

  AppGuideItem copyWith({
    String? id,
    String? moduleId,
    String? groupId,
    String? pageId,
    String? title,
    String? description,
    IconData? icon,
    List<String>? keywords,
    AppGuideItemType? type,
    int? priority,
    bool? preferInSearch,
    String? fallbackId,
    String? beforeHighlightActionId,
    List<String>? searchableExtra,
    Future<void> Function()? openAction,
    Future<void> Function()? beforeHighlight,
    BorderRadius? targetBorderRadius,
    EdgeInsets? targetPadding,
    TooltipPosition? tooltipPosition,
  }) {
    return AppGuideItem(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      groupId: groupId ?? this.groupId,
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      keywords: keywords ?? this.keywords,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      preferInSearch: preferInSearch ?? this.preferInSearch,
      fallbackId: fallbackId ?? this.fallbackId,
      beforeHighlightActionId:
          beforeHighlightActionId ?? this.beforeHighlightActionId,
      searchableExtra: searchableExtra ?? this.searchableExtra,
      openAction: openAction ?? this.openAction,
      beforeHighlight: beforeHighlight ?? this.beforeHighlight,
      targetBorderRadius: targetBorderRadius ?? this.targetBorderRadius,
      targetPadding: targetPadding ?? this.targetPadding,
      tooltipPosition: tooltipPosition ?? this.tooltipPosition,
    );
  }
}
