import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';

import 'vnu_select_field.dart';
import 'vnu_select_item.dart';
import 'vnu_select_option_tile.dart';
import 'vnu_select_sheet.dart';
import 'vnu_select_theme.dart';

class VnuDrillDownGroup<P, C> {
  const VnuDrillDownGroup({
    required this.parent,
    required this.children,
  });

  final VnuSelectItem<P> parent;
  final List<VnuSelectItem<C>> children;
}

class VnuDrillDownSelection<P, C> {
  const VnuDrillDownSelection({
    required this.parent,
    required this.child,
  });

  final P parent;
  final C child;
}

class VnuDrillDownSelect<P, C> extends StatelessWidget {
  const VnuDrillDownSelect({
    super.key,
    required this.groups,
    required this.onSelected,
    required this.hintText,
    this.value,
    this.label,
    this.parentTitle = 'Chọn nhóm',
    this.childTitle = 'Chọn mục',
    this.displayText,
    this.enabled = true,
    this.guideTargetId,
    this.requiredField = false,
  });

  final List<VnuDrillDownGroup<P, C>> groups;
  final VnuDrillDownSelection<P, C>? value;
  final ValueChanged<VnuDrillDownSelection<P, C>> onSelected;
  final String hintText;
  final String? label;
  final String parentTitle;
  final String childTitle;
  final String Function(VnuDrillDownSelection<P, C>)? displayText;
  final bool enabled;
  final String? guideTargetId;
  final bool requiredField;

  String _displayValue() {
    final current = value;
    if (current == null) return '';
    if (displayText != null) return displayText!(current);

    String? parentLabel;
    String? childLabel;
    for (final group in groups) {
      if (group.parent.value == current.parent) {
        parentLabel = group.parent.label;
        for (final child in group.children) {
          if (child.value == current.child) {
            childLabel = child.label;
            break;
          }
        }
        break;
      }
    }
    return [parentLabel, childLabel]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
  }

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    final result = await showModalBottomSheet<VnuDrillDownSelection<P, C>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DrillDownPicker<P, C>(
        groups: groups,
        initialValue: value,
        parentTitle: parentTitle,
        childTitle: childTitle,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return VnuSelectField(
      label: label,
      displayText: _displayValue(),
      placeholder: hintText,
      onTap: () => _open(context),
      enabled: enabled,
      guideTargetId: guideTargetId,
      requiredField: requiredField,
    );
  }
}

class _DrillDownPicker<P, C> extends StatefulWidget {
  const _DrillDownPicker({
    required this.groups,
    required this.initialValue,
    required this.parentTitle,
    required this.childTitle,
  });

  final List<VnuDrillDownGroup<P, C>> groups;
  final VnuDrillDownSelection<P, C>? initialValue;
  final String parentTitle;
  final String childTitle;

  @override
  State<_DrillDownPicker<P, C>> createState() => _DrillDownPickerState<P, C>();
}

class _DrillDownPickerState<P, C> extends State<_DrillDownPicker<P, C>> {
  VnuDrillDownGroup<P, C>? _draftParent;

  @override
  void initState() {
    super.initState();
    final current = widget.initialValue;
    if (current != null) {
      for (final group in widget.groups) {
        if (group.parent.value == current.parent) {
          _draftParent = group;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = _draftParent;
    final title = parent == null
        ? widget.parentTitle
        : '${widget.childTitle} · ${parent.parent.label}';

    return VnuSelectSheetFrame(
      title: title,
      showBack: parent != null,
      onBack: parent == null ? null : () => setState(() => _draftParent = null),
      child: ListView(
        padding: VnuSelectTheme.sheetBodyPadding,
        children: parent == null
            ? [
                for (final group in widget.groups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: VnuSelectOptionTile(
                      title: group.parent.label,
                      subtitle: group.parent.subtitle,
                      enabled: group.parent.enabled,
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                      onTap: () => setState(() => _draftParent = group),
                    ),
                  ),
              ]
            : [
                for (final child in parent.children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: VnuSelectOptionTile(
                      title: child.label,
                      subtitle: child.subtitle,
                      enabled: child.enabled,
                      selected: widget.initialValue?.parent ==
                              parent.parent.value &&
                          widget.initialValue?.child == child.value,
                      onTap: () => Navigator.of(context).pop(
                        VnuDrillDownSelection<P, C>(
                          parent: parent.parent.value,
                          child: child.value,
                        ),
                      ),
                    ),
                  ),
              ],
      ),
    );
  }
}
