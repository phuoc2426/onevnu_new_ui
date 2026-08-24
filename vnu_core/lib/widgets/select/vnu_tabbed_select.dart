import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';

import 'vnu_select_field.dart';
import 'vnu_select_item.dart';
import 'vnu_select_option_tile.dart';
import 'vnu_select_sheet.dart';
import 'vnu_select_theme.dart';

class VnuSelectTab<T> {
  const VnuSelectTab({required this.label, required this.items});
  final String label;
  final List<VnuSelectItem<T>> items;
}

class VnuTabbedSelect<T> extends StatelessWidget {
  const VnuTabbedSelect({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    required this.hintText,
    this.label,
    this.sheetTitle = 'Chọn giá trị',
    this.guideTargetId,
  });

  final List<VnuSelectTab<T>> tabs;
  final T? value;
  final ValueChanged<T> onChanged;
  final String hintText;
  final String? label;
  final String sheetTitle;
  final String? guideTargetId;

  String _display() {
    for (final tab in tabs) {
      for (final item in tab.items) {
        if (item.value == value) return item.label;
      }
    }
    return '';
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<_TabbedSelection<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TabbedPicker<T>(
        tabs: tabs,
        selected: value,
        title: sheetTitle,
      ),
    );
    if (result != null) onChanged(result.value);
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

class _TabbedSelection<T> {
  const _TabbedSelection(this.value);
  final T value;
}

class _TabbedPicker<T> extends StatefulWidget {
  const _TabbedPicker({
    required this.tabs,
    required this.selected,
    required this.title,
  });
  final List<VnuSelectTab<T>> tabs;
  final T? selected;
  final String title;

  @override
  State<_TabbedPicker<T>> createState() => _TabbedPickerState<T>();
}

class _TabbedPickerState<T> extends State<_TabbedPicker<T>> {
  int _tabIndex = 0;
  T? _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.selected;
    for (var i = 0; i < widget.tabs.length; i++) {
      if (widget.tabs[i].items.any((item) => item.value == widget.selected)) {
        _tabIndex = i;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.tabs.isEmpty ? null : widget.tabs[_tabIndex];
    return VnuSelectSheetFrame(
      title: widget.title,
      footer: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          10,
          14,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: FilledButton(
          onPressed: _draft == null
              ? null
              : () => Navigator.of(context).pop(
                    _TabbedSelection<T>(_draft as T),
                  ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.greenAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Áp dụng'),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.tabs.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.tabs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 120),
                        child: FilledButton(
                          onPressed: () => setState(() => _tabIndex = i),
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: i == _tabIndex
                                ? AppColors.greenAccent
                                : const Color(0xFFF1F2F4),
                            foregroundColor: i == _tabIndex
                                ? Colors.white
                                : AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            widget.tabs[i].label,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (widget.tabs.length > 1)
            const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: current == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: VnuSelectTheme.sheetBodyPadding,
                    children: [
                      for (final item in current.items)
                        VnuSelectOptionTile(
                          title: item.label,
                          subtitle: item.subtitle,
                          enabled: item.enabled,
                          selected: item.value == _draft,
                          onTap: () => setState(() => _draft = item.value),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

