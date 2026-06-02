import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/empty_data_widget.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:intl/intl.dart';

class DRHistoryBottomSheet extends StatefulWidget {
  final int registrationId;
  const DRHistoryBottomSheet({super.key, required this.registrationId});

  @override
  State<DRHistoryBottomSheet> createState() => _DRHistoryBottomSheetState();
}

class _DRHistoryBottomSheetState extends State<DRHistoryBottomSheet> {
  final _cubit = DormitoryRegistrationCubit();

  @override
  void initState() {
    super.initState();
    _cubit.getRegistrationHistories(widget.registrationId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: BlocBuilder<DormitoryRegistrationCubit, DormitoryRegistrationState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is DormitoryRegistrationLoading ||
              state is DormitoryRegistrationShowHub) {
            return const SizedBox(
              height: 200,
              child: Center(child: LoadingIndicator()),
            );
          }

          if (state is DormitoryRegistrationError) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (state is DormitoryRegistrationHistoryLoaded) {
            final list = state.history;
            if (list.isEmpty) {
              return const SizedBox(
                height: 200,
                child: EmptyDataWidget(),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lịch sử xử lý',
                      style: AppTheme.headline6.copyWith(
                        color: AppTheme.textTitleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final isLast = index == list.length - 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? AppTheme.backgroundBlueColor
                                      : Colors.grey[300],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: index == 0
                                        ? AppTheme.backgroundBlueColor.withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 50,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.action ?? 'Cập nhật trạng thái',
                                  style: AppTheme.subtitle2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textTitleColor,
                                  ),
                                ),
                                if (item.note != null &&
                                    item.note!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.note!,
                                    style: AppTheme.body2.copyWith(
                                      color: AppTheme.textSubColor,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (item.createdAt != null)
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(item.createdAt!),
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.textSubColor,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox(
            height: 200,
            child: Center(child: Text('Đang tải...')),
          );
        },
      ),
    );
  }
}
