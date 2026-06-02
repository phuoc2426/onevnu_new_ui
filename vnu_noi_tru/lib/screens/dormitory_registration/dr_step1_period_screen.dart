import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/widgets/nt_custom_dropdown.dart';

class DRStep1PeriodScreen extends StatefulWidget {
  const DRStep1PeriodScreen({super.key});

  @override
  State<DRStep1PeriodScreen> createState() => _DRStep1PeriodScreenState();
}

class _DRStep1PeriodScreenState extends State<DRStep1PeriodScreen> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DormitoryRegistrationCubit>();

    return BlocBuilder<DormitoryRegistrationCubit, DormitoryRegistrationState>(
      builder: (context, state) {
        if (state is DormitoryRegistrationLoading && cubit.periods.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.colorMain),
          );
        }

        if (cubit.periods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Không có đợt đăng ký nào đang mở',
                  style: TextStyle(color: Colors.grey[600], fontSize: AppFontSizes.mediumSmall),
                ),
              ],
            ),
          );
        }

        // Set default selected period if not selected yet
        if (cubit.selectedPeriod == null && cubit.periods.isNotEmpty) {
          cubit.selectedPeriod = cubit.periods.first;
        }

        final period = cubit.selectedPeriod ?? cubit.periods.first;
        final statusText = period.status == 'open' ? 'Đang mở' : 'Đã đóng';
        final isStatusOpen = period.status == 'open';

        // Calculate remaining days
        int remainDays = 0;
        if (period.endTime != null) {
          remainDays = period.endTime!.difference(DateTime.now()).inDays;
          if (remainDays < 0) remainDays = 0;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card: Period selection
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE3E6EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF8EF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_box_outlined, color: Color(0xFF078B3E), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Đợt đăng ký',
                            style: TextStyle(
                              fontSize: AppFontSizes.small,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111318),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dropdown select
                      NtCustomDropdown<RegistrationPeriodModel>(
                        label: 'Đợt đăng ký',
                        hintText: 'Chọn đợt đăng ký',
                        value: period,
                        items: cubit.periods,
                        itemAsString: (item) => item.name ?? 'Đợt đăng ký',
                        onChanged: (value) {
                          setState(() {
                            cubit.selectedPeriod = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Metadata row
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isStatusOpen ? const Color(0xFFEAF8EF) : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isStatusOpen ? const Color(0xFF078B3E) : const Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: isStatusOpen ? const Color(0xFF078B3E) : const Color(0xFFDC2626),
                                    fontSize: AppFontSizes.font11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF666B75)),
                          Text(
                            '${period.startTime != null ? DateFormat('dd/MM/yyyy').format(period.startTime!) : '-'} - ${period.endTime != null ? DateFormat('dd/MM/yyyy').format(period.endTime!) : '-'}',
                            style: const TextStyle(
                              color: Color(0xFF111318),
                              fontSize: AppFontSizes.small,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Period description
                      Text(
                        period.description ?? 'Không có mô tả cho đợt này.',
                        style: const TextStyle(
                          color: Color(0xFF666B75),
                          fontSize: AppFontSizes.small,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notice banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEDF9F1), Color(0xFFE4F5E9)],
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Color(0xFF078B3E), size: 18),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Color(0xFF1C2D22), fontSize: AppFontSizes.small),
                                children: [
                                  const TextSpan(text: 'Còn '),
                                  TextSpan(
                                    text: '$remainDays ngày',
                                    style: const TextStyle(
                                      color: Color(0xFF078B3E),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const TextSpan(text: ' để đăng ký'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
