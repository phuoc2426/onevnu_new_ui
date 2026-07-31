import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class NtCustomDropdown<T> extends StatelessWidget {
  static const Color _green = Color(0xFF078B3E);
  static const Color _text = Color(0xFF111318);
  static const Color _muted = Color(0xFF666B75);
  static const Color _border = Color(0xFFDCE3DF);
  static const Color _error = Color(0xFFDC2626);

  final String label;
  final String hintText;
  final T? value;
  final List<T> items;
  final String Function(T) itemAsString;
  final String Function(T)? itemAsSubtitle;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool clearable;
  final String? clearableText;

  const NtCustomDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.itemAsString,
    this.itemAsSubtitle,
    required this.onChanged,
    this.validator,
    this.clearable = false,
    this.clearableText,
  });

  bool get hasValue => value != null;

  ThemeData _greenTheme(BuildContext context) {
    final ThemeData base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: _green,
        secondary: _green,
        surface: Colors.white,
      ),
      splashColor: const Color(0x14078B3E),
      highlightColor: const Color(0x0F078B3E),
    );
  }

  Future<void> _showPicker(
    BuildContext context,
    FormFieldState<T> fieldState,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Theme(
          data: _greenTheme(sheetContext),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 8, 8),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5D8DE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: _green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: AppFontSizes.medium,
                                fontWeight: FontWeight.w800,
                                color: _text,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE9ECEF)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    itemCount: items.length + (clearable ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      if (clearable && index == 0) {
                        return _buildOptionTile(
                          selected: value == null,
                          title: clearableText ?? 'Không chọn',
                          icon: Icons.remove_circle_outline_rounded,
                          onTap: () {
                            fieldState.didChange(null);
                            onChanged(null);
                            Navigator.pop(sheetContext);
                          },
                        );
                      }

                      final int itemIndex = index - (clearable ? 1 : 0);
                      final T item = items[itemIndex];
                      return _buildOptionTile(
                        selected: item == value,
                        title: itemAsString(item),
                        subtitle: itemAsSubtitle?.call(item),
                        icon: Icons.radio_button_checked_rounded,
                        onTap: () {
                          fieldState.didChange(item);
                          onChanged(item);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required bool selected,
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFEAF7EF) : const Color(0xFFF9FAFA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF9FD8B2) : const Color(0xFFE3E7E5),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                color: selected ? _green : const Color(0xFF9AA0A8),
                size: 21,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppFontSizes.mediumSmall,
                        color: selected ? _green : _text,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: AppFontSizes.extraSmall,
                          color: _muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final T? localValue = value;
    final String text =
        localValue != null ? itemAsString(localValue) : hintText;

    return Theme(
      data: _greenTheme(context),
      child: FormField<T>(
        validator: validator,
        initialValue: value,
        builder: (FormFieldState<T> state) {
          final bool hasError = state.hasError;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showPicker(context, state),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 56,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasError
                            ? _error
                            : hasValue
                                ? const Color(0xFF9FD8B2)
                                : _border,
                        width: hasError || hasValue ? 1.4 : 1,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                label,
                                style: TextStyle(
                                  color: hasError ? _error : _muted,
                                  fontSize: AppFontSizes.extraSmall,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasValue
                                      ? _text
                                      : const Color(0xFF9AA0A8),
                                  fontSize: AppFontSizes.mediumSmall,
                                  fontWeight: hasValue
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: hasValue
                                ? const Color(0xFFEAF7EF)
                                : const Color(0xFFF2F4F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _green,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4),
                  child: Text(
                    state.errorText ?? '',
                    style: const TextStyle(
                      color: _error,
                      fontSize: AppFontSizes.extraSmall,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
