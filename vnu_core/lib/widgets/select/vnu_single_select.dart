import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_select_field.dart';
import 'vnu_select_item.dart';
import 'vnu_select_option_tile.dart';
import 'vnu_select_search.dart';
import 'vnu_select_sheet.dart';
import 'vnu_select_theme.dart';

class VnuSingleSelect<T> extends StatefulWidget {
  const VnuSingleSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.hintText,
    this.label,
    this.sheetTitle,
    this.validator,
    this.enabled = true,
    this.clearable = false,
    this.clearLabel = 'Không chọn',
    this.searchable = false,
    this.searchHint = 'Tìm kiếm',
    this.requiredField = false,
    this.guideTargetId,
    this.leading,
    this.compact = false,
  });

  final List<VnuSelectItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final String? label;
  final String? sheetTitle;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool clearable;
  final String clearLabel;
  final bool searchable;
  final String searchHint;
  final bool requiredField;
  final String? guideTargetId;
  final Widget? leading;
  final bool compact;

  @override
  State<VnuSingleSelect<T>> createState() => _VnuSingleSelectState<T>();
}

class _VnuSingleSelectState<T> extends State<VnuSingleSelect<T>> {
  final GlobalKey<FormFieldState<T>> _formKey = GlobalKey<FormFieldState<T>>();

  @override
  void didUpdateWidget(covariant VnuSingleSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final state = _formKey.currentState;
        if (state != null && state.value != widget.value) {
          state.didChange(widget.value);
        }
      });
    }
  }

  VnuSelectItem<T>? _selectedItem(T? value) {
    if (value == null) return null;
    for (final item in widget.items) {
      if (item.value == value) return item;
    }
    return null;
  }

  Future<void> _openPicker(FormFieldState<T> fieldState) async {
    if (!widget.enabled) return;

    final picked = await VnuSelectSheet.show<_NullableSelection<T>>(
      context: context,
      title: widget.sheetTitle ?? widget.label ?? widget.hintText,
      bodyBuilder: (_) => _SingleSelectBody<T>(
        items: widget.items,
        selectedValue: fieldState.value,
        clearable: widget.clearable,
        clearLabel: widget.clearLabel,
        searchable: widget.searchable,
        searchHint: widget.searchHint,
      ),
    );

    if (!mounted || picked == null) return;
    fieldState.didChange(picked.value);
    widget.onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: _formKey,
      initialValue: widget.value,
      enabled: widget.enabled,
      validator: widget.validator,
      builder: (fieldState) {
        final selected = _selectedItem(fieldState.value);
        return VnuSelectField(
          label: widget.label,
          displayText: selected?.label ?? '',
          placeholder: widget.hintText,
          onTap: () => _openPicker(fieldState),
          enabled: widget.enabled,
          errorText: fieldState.errorText,
          requiredField: widget.requiredField,
          guideTargetId: widget.guideTargetId,
          leading: widget.leading,
          compact: widget.compact,
        );
      },
    );
  }
}

class _NullableSelection<T> {
  const _NullableSelection(this.value);
  final T? value;
}

class _SingleSelectBody<T> extends StatefulWidget {
  const _SingleSelectBody({
    required this.items,
    required this.selectedValue,
    required this.clearable,
    required this.clearLabel,
    required this.searchable,
    required this.searchHint,
  });

  final List<VnuSelectItem<T>> items;
  final T? selectedValue;
  final bool clearable;
  final String clearLabel;
  final bool searchable;
  final String searchHint;

  @override
  State<_SingleSelectBody<T>> createState() => _SingleSelectBodyState<T>();
}

class _SingleSelectBodyState<T> extends State<_SingleSelectBody<T>> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VnuSelectItem<T>> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items.where((item) {
      return item.effectiveSearchText.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.searchable) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: VnuSelectSearch(
              controller: _searchController,
              hintText: widget.searchHint,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ],
        Flexible(
          child: items.isEmpty && !(widget.clearable && _query.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      'Không tìm thấy lựa chọn phù hợp.',
                      textAlign: TextAlign.center,
                      style: TextStyles.regular.copyWith(
                        fontSize: AppFontSizes.mediumSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: VnuSelectTheme.sheetBodyPadding,
                  children: [
                    if (widget.clearable && _query.isEmpty)
                      VnuSelectOptionTile(
                        title: widget.clearLabel,
                        selected: widget.selectedValue == null,
                        leading: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () => Navigator.of(context).pop(
                          _NullableSelection<T>(null),
                        ),
                      ),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: VnuSelectOptionTile(
                          title: item.label,
                          subtitle: item.subtitle,
                          enabled: item.enabled,
                          selected: item.value == widget.selectedValue,
                          onTap: () => Navigator.of(context).pop(
                            _NullableSelection<T>(item.value),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
