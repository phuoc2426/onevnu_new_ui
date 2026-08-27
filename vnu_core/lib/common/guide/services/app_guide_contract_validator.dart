import 'package:flutter/foundation.dart';

import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';

class AppGuideContractIssue {
  const AppGuideContractIssue(this.message);

  final String message;

  @override
  String toString() => message;
}

/// P5 semantic contract validator.
///
/// This validates the static contract that later becomes the capability list
/// for a dynamic guide backend. Runtime anchor visibility is intentionally not
/// checked here because anchors only exist after their widgets are mounted.
class AppGuideContractValidator {
  const AppGuideContractValidator._();

  static List<AppGuideContractIssue> validate({
    required List<AppGuideItem> items,
    required List<AppGuideGroup> groups,
  }) {
    final issues = <AppGuideContractIssue>[];

    final itemIds = <String>{};
    final groupIds = <String>{};

    for (final item in items) {
      final id = item.id.trim();
      if (id.isEmpty) {
        issues.add(const AppGuideContractIssue('Guide item has an empty id.'));
        continue;
      }

      if (!itemIds.add(id)) {
        issues.add(AppGuideContractIssue('Duplicate guide item id: $id'));
      }

      if (item.groupId.trim().isEmpty) {
        issues.add(AppGuideContractIssue('Guide item $id has an empty groupId.'));
      }

      if (item.moduleId.trim().isEmpty) {
        issues.add(AppGuideContractIssue('Guide item $id has an empty moduleId.'));
      }

      final actionId = item.beforeHighlightActionId?.trim();
      if (actionId != null && actionId.isEmpty) {
        issues.add(
          AppGuideContractIssue(
            'Guide item $id has an empty beforeHighlightActionId.',
          ),
        );
      }

      final fallbackId = item.fallbackId?.trim();
      if (fallbackId != null && fallbackId.isEmpty) {
        issues.add(AppGuideContractIssue('Guide item $id has an empty fallbackId.'));
      }
      if (fallbackId == id) {
        issues.add(AppGuideContractIssue('Guide item $id falls back to itself.'));
      }

      if (item.preferInSearch &&
          item.isNavigationItem &&
          item.openAction == null &&
          item.beforeHighlightActionId == null) {
        issues.add(
          AppGuideContractIssue(
            'Guide item $id is advertised as navigation but has no navigation action.',
          ),
        );
      }
    }

    for (final group in groups) {
      final id = group.id.trim();
      if (id.isEmpty) {
        issues.add(const AppGuideContractIssue('Guide group has an empty id.'));
        continue;
      }

      if (!groupIds.add(id)) {
        issues.add(AppGuideContractIssue('Duplicate guide group id: $id'));
      }

      if (group.moduleId.trim().isEmpty) {
        issues.add(AppGuideContractIssue('Guide group $id has an empty moduleId.'));
      }

      final seenTargets = <String>{};
      for (final rawTargetId in group.targetIds) {
        final targetId = rawTargetId.trim();
        if (targetId.isEmpty) {
          issues.add(AppGuideContractIssue('Guide group $id has an empty targetId.'));
          continue;
        }
        if (!seenTargets.add(targetId)) {
          issues.add(
            AppGuideContractIssue(
              'Guide group $id contains duplicate targetId: $targetId',
            ),
          );
        }
      }
    }

    final itemById = <String, AppGuideItem>{
      for (final item in items)
        if (item.id.trim().isNotEmpty) item.id: item,
    };
    final groupById = <String, AppGuideGroup>{
      for (final group in groups)
        if (group.id.trim().isNotEmpty) group.id: group,
    };

    for (final item in items) {
      final group = groupById[item.groupId];
      if (group == null) {
        issues.add(
          AppGuideContractIssue(
            'Guide item ${item.id} references missing group ${item.groupId}.',
          ),
        );
      } else if (group.moduleId != item.moduleId) {
        issues.add(
          AppGuideContractIssue(
            'Guide item ${item.id} module ${item.moduleId} does not match '
            'group ${group.id} module ${group.moduleId}.',
          ),
        );
      }

      final fallbackId = item.fallbackId;
      if (fallbackId != null && itemById[fallbackId] == null) {
        issues.add(
          AppGuideContractIssue(
            'Guide item ${item.id} references missing fallback $fallbackId.',
          ),
        );
      }
    }

    for (final group in groups) {
      for (final targetId in group.targetIds) {
        final target = itemById[targetId];
        if (target == null) {
          issues.add(
            AppGuideContractIssue(
              'Guide group ${group.id} references missing item $targetId.',
            ),
          );
          continue;
        }

        if (target.groupId != group.id) {
          issues.add(
            AppGuideContractIssue(
              'Guide group ${group.id} targets $targetId, but the item belongs '
              'to group ${target.groupId}.',
            ),
          );
        }
      }
    }

    return issues;
  }

  static void debugValidateOrThrow({
    required List<AppGuideItem> items,
    required List<AppGuideGroup> groups,
  }) {
    if (!kDebugMode) return;

    final issues = validate(items: items, groups: groups);
    if (issues.isEmpty) {
      debugPrint(
        '[GUIDE_CONTRACT_OK] items=${items.length} groups=${groups.length}',
      );
      return;
    }

    for (final issue in issues) {
      debugPrint('[GUIDE_CONTRACT_ERROR] $issue');
    }

    throw FlutterError(
      'App Guide semantic contract is invalid (${issues.length} issue(s)).\n'
      '${issues.map((e) => '- $e').join('\n')}',
    );
  }
}
