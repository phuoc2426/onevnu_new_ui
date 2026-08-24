import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_select_field.dart';
import 'vnu_select_group.dart';
import 'vnu_select_option_tile.dart';
import 'vnu_select_sheet.dart';
import 'vnu_select_theme.dart';

class VnuAccordionSelect<T> extends StatelessWidget {
  const VnuAccordionSelect({
    super.key,
    required this.groups,
    required this.value,
    required this.onChanged,
    required this.hintText,
    this.label,
    this.sheetTitle = 'Chọn mục',
    this.guideTargetId,
    this.enabled = true,
  });

  final List<VnuSelectGroup<T>> groups;
  final T? value;
  final ValueChanged<T> onChanged;
  final String hintText;
  final String? label;
  final String sheetTitle;
  final String? guideTargetId;
  final bool enabled;

  String _labelForValue() {
    for (final group in groups) {
      for (final item in group.items) {
        if (item.value == value) return item.label;
      }
    }
    return '';
  }

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    final picked = await showModalBottomSheet<_AccordionSelection<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccordionPicker<T>(
        groups: groups,
        selected: value,
        title: sheetTitle,
      ),
    );
    if (picked != null) onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    return VnuSelectField(
      label: label,
      displayText: _labelForValue(),
      placeholder: hintText,
      enabled: enabled,
      onTap: () => _open(context),
      guideTargetId: guideTargetId,
    );
  }
}

class _AccordionSelection<T> {
  const _AccordionSelection(this.value);
  final T value;
}

class _AccordionPicker<T> extends StatefulWidget {
  const _AccordionPicker({
    required this.groups,
    required this.selected,
    required this.title,
  });

  final List<VnuSelectGroup<T>> groups;
  final T? selected;
  final String title;

  @override
  State<_AccordionPicker<T>> createState() => _AccordionPickerState<T>();
}

class _AccordionPickerState<T> extends State<_AccordionPicker<T>> {
  late final Set<int> _expanded;
  T? _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.selected;
    _expanded = {
      for (var i = 0; i < widget.groups.length; i++)
        if (widget.groups[i].initiallyExpanded || i == 0) i,
    };
  }

  @override
  Widget build(BuildContext context) {
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
                    _AccordionSelection<T>(_draft as T),
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
      child: ListView.builder(
        padding: VnuSelectTheme.sheetBodyPadding,
        itemCount: widget.groups.length,
        itemBuilder: (context, index) {
          final group = widget.groups[index];
          final open = _expanded.contains(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() {
                  open ? _expanded.remove(index) : _expanded.add(index);
                }),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.label,
                            style: TextStyles.bold.copyWith(
                              fontSize: AppFontSizes.mediumSmall,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '(${group.items.length})',
                          style: TextStyles.regular.copyWith(
                            fontSize: AppFontSizes.small,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (open)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Column(
                    children: [
                      for (final item in group.items)
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
              const Divider(height: 1, color: AppColors.divider),
            ],
          );
        },
      ),
    );
  }
}
