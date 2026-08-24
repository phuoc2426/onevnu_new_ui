import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';

import 'vnu_select_field.dart';
import 'vnu_select_item.dart';
import 'vnu_select_option_tile.dart';
import 'vnu_select_sheet.dart';
import 'vnu_select_theme.dart';

class VnuStackedSelection<A, B> {
  const VnuStackedSelection({required this.first, required this.second});
  final A first;
  final B second;
}

class VnuStackedSelect<A, B> extends StatelessWidget {
  const VnuStackedSelect({
    super.key,
    required this.firstItems,
    required this.secondItems,
    required this.onSelected,
    required this.hintText,
    this.value,
    this.label,
    this.firstTitle = 'Chọn bước 1',
    this.secondTitle = 'Chọn bước 2',
    this.guideTargetId,
  });

  final List<VnuSelectItem<A>> firstItems;
  final List<VnuSelectItem<B>> secondItems;
  final VnuStackedSelection<A, B>? value;
  final ValueChanged<VnuStackedSelection<A, B>> onSelected;
  final String hintText;
  final String? label;
  final String firstTitle;
  final String secondTitle;
  final String? guideTargetId;

  String _display() {
    final current = value;
    if (current == null) return '';
    String first = '';
    String second = '';
    for (final item in firstItems) {
      if (item.value == current.first) first = item.label;
    }
    for (final item in secondItems) {
      if (item.value == current.second) second = item.label;
    }
    return [first, second].where((e) => e.isNotEmpty).join(' · ');
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<VnuStackedSelection<A, B>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StackedPicker<A, B>(
        firstItems: firstItems,
        secondItems: secondItems,
        initialValue: value,
        firstTitle: firstTitle,
        secondTitle: secondTitle,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return VnuSelectField(
      label: label,
      displayText: _display(),
      placeholder: hintText,
      onTap: () => _open(context),
      guideTargetId: guideTargetId,
    );
  }
}

class _StackedPicker<A, B> extends StatefulWidget {
  const _StackedPicker({
    required this.firstItems,
    required this.secondItems,
    required this.initialValue,
    required this.firstTitle,
    required this.secondTitle,
  });

  final List<VnuSelectItem<A>> firstItems;
  final List<VnuSelectItem<B>> secondItems;
  final VnuStackedSelection<A, B>? initialValue;
  final String firstTitle;
  final String secondTitle;

  @override
  State<_StackedPicker<A, B>> createState() => _StackedPickerState<A, B>();
}

class _StackedPickerState<A, B> extends State<_StackedPicker<A, B>> {
  A? _draftFirst;
  bool _secondStep = false;

  String _labelForFirst(A value) {
    for (final item in widget.firstItems) {
      if (item.value == value) return item.label;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _secondStep && _draftFirst != null
        ? 'Đã chọn: ${_labelForFirst(_draftFirst as A)}'
        : null;

    return VnuSelectSheetFrame(
      title: _secondStep ? widget.secondTitle : widget.firstTitle,
      subtitle: subtitle,
      showBack: _secondStep,
      onBack: _secondStep ? () => setState(() => _secondStep = false) : null,
      child: ListView(
        padding: VnuSelectTheme.sheetBodyPadding,
        children: !_secondStep
            ? [
                for (final item in widget.firstItems)
                  VnuSelectOptionTile(
                    title: item.label,
                    subtitle: item.subtitle,
                    enabled: item.enabled,
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textHint,
                    ),
                    onTap: () {
                      setState(() {
                        _draftFirst = item.value;
                        _secondStep = true;
                      });
                    },
                  ),
              ]
            : [
                for (final item in widget.secondItems)
                  VnuSelectOptionTile(
                    title: item.label,
                    subtitle: item.subtitle,
                    enabled: item.enabled,
                    selected: widget.initialValue?.first == _draftFirst &&
                        widget.initialValue?.second == item.value,
                    onTap: () {
                      final first = _draftFirst;
                      if (first == null) return;
                      Navigator.of(context).pop(
                        VnuStackedSelection<A, B>(
                          first: first,
                          second: item.value,
                        ),
                      );
                    },
                  ),
              ],
      ),
    );
  }
}
