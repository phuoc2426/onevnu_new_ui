import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class NtCustomDropdown<T> extends StatelessWidget {
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


  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.only(top: 10, bottom: 24, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull handle bar
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E6EB),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppFontSizes.medium,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF666B75)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (clearable) ...[
                InkWell(
                  onTap: () {
                    onChanged(null);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            clearableText ?? 'Không chọn',
                            style: TextStyle(
                              fontSize: AppFontSizes.mediumSmall,
                              color: value == null ? const Color(0xFF078B3E) : const Color(0xFF111318),
                              fontWeight: value == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (value == null)
                          const Icon(Icons.check, color: Color(0xFF078B3E), size: 18),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
              ],
              // Items List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F3F5)),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == value;
                    final text = itemAsString(item);

                    return InkWell(
                      onTap: () {
                        onChanged(item);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: AppFontSizes.mediumSmall,
                                      color: isSelected ? const Color(0xFF078B3E) : const Color(0xFF111318),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (itemAsSubtitle != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      itemAsSubtitle!(item),
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.extraSmall,
                                        color: Color(0xFF666B75),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check, color: Color(0xFF078B3E), size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localValue = value;
    final text = localValue != null ? itemAsString(localValue) : hintText;

    return FormField<T>(
      validator: validator,
      initialValue: value,
      builder: (FormFieldState<T> state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showPicker(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasError
                        ? const Color(0xFFDC2626)
                        : (hasValue ? const Color(0xFF078B3E) : const Color(0xFFCFD4DC)),
                    width: hasError || hasValue ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: hasError ? const Color(0xFFDC2626) : const Color(0xFF666B75),
                              fontSize: AppFontSizes.extraSmall,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            text,
                            style: TextStyle(
                              color: hasValue ? const Color(0xFF111318) : const Color(0xFF9AA0A8),
                              fontSize: AppFontSizes.mediumSmall,
                              fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF80848B), size: 20),
                  ],
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: AppFontSizes.extraSmall,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
