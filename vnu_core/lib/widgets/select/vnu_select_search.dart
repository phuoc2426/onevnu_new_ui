import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/widgets/field/vnu_field_metrics.dart';

class VnuSelectSearch extends StatelessWidget {
  const VnuSelectSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Tìm kiếm',
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      scrollPhysics: const ClampingScrollPhysics(),
      textAlignVertical: TextAlignVertical.center,
      style: TextStyles.regular.copyWith(fontSize: AppFontSizes.mediumSmall),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyles.regular.copyWith(
          fontSize: AppFontSizes.mediumSmall,
          color: AppColors.textHint,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa tìm kiếm',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: const Color(0xFFF7F8F9),
        isDense: true,
        constraints: BoxConstraints(
          minHeight: VnuFieldMetrics.minHeightFor(context, compact: true),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greenAccent, width: 1.4),
        ),
      ),
    );
  }
}
