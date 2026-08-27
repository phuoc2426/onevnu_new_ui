import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

/// OneVNU date picker presented as a branded bottom sheet instead of the
/// platform/default Material date dialog.
///
/// All feature screens should route date-only selection through this helper so
/// Android/iOS keep the same green interaction language and Vietnamese action
/// labels.
class VnuDatePickerSheet {
  VnuDatePickerSheet._();

  static Future<DateTime?> show({
    required BuildContext context,
    required String title,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String cancelText = 'Hủy',
    String confirmText = 'Chọn ngày',
  }) {
    final DateTime first = DateUtils.dateOnly(firstDate);
    final DateTime last = DateUtils.dateOnly(lastDate);
    DateTime selected = DateUtils.dateOnly(initialDate);

    if (selected.isBefore(first)) selected = first;
    if (selected.isAfter(last)) selected = last;

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.34),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setModalState,
          ) {
            final ThemeData base = Theme.of(context);
            final ThemeData greenTheme = base.copyWith(
              colorScheme: base.colorScheme.copyWith(
                primary: AppColors.greenAccent,
                secondary: AppColors.greenAccent,
                surface: Colors.white,
                onPrimary: Colors.white,
              ),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: AppColors.greenAccent,
                selectionColor: Color(0x3316A34A),
                selectionHandleColor: AppColors.greenAccent,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.greenAccent,
                ),
              ),
            );

            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE2DE),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.greenAccent,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.bold.copyWith(
                                  fontSize: AppFontSizes.medium,
                                  color: AppColors.textTitle,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(selected),
                                style: TextStyles.semiBold.copyWith(
                                  fontSize: AppFontSizes.small,
                                  color: AppColors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Theme(
                      data: greenTheme,
                      child: CalendarDatePicker(
                        initialDate: selected,
                        firstDate: first,
                        lastDate: last,
                        onDateChanged: (DateTime value) {
                          setModalState(() {
                            selected = DateUtils.dateOnly(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(cancelText),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context, selected),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.greenAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(confirmText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }
}
