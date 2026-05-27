import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/app_colors.dart';

import '../cubit/hoc_bong_list_cubit.dart';
import '../cubit/hoc_bong_states.dart';
import '../models/hoc_bong_models.dart';
import '../repository/hoc_bong_repository.dart';
import '../widgets/hoc_bong_card.dart';
import '../widgets/hoc_bong_empty_state.dart';
import '../widgets/hoc_bong_screen_shell.dart';
import 'hoc_bong_detail_screen.dart';
import 'hoc_bong_my_applications_screen.dart';

class HocBongListScreen extends StatefulWidget {
  final HocBongRepository? repository;

  const HocBongListScreen({super.key, this.repository});

  @override
  State<HocBongListScreen> createState() => _HocBongListScreenState();
}

class _HocBongListScreenState extends State<HocBongListScreen> {
  late final HocBongRepository repository;
  late final HocBongListCubit cubit;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? HocBongRepository.createDefault();
    cubit = HocBongListCubit(repository)..load();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    cubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await cubit.refresh();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return HocBongScreenShell(
      title: 'Học bổng',
      actions: [
        IconButton(
          icon: const Icon(Icons.assignment_outlined, color: Colors.black87),
          tooltip: 'Hồ sơ của tôi',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HocBongMyApplicationsScreen(repository: repository)),
          ).then((_) => cubit.refresh()),
        ),
      ],
      body: BlocBuilder<HocBongListCubit, HocBongListState>(
        bloc: cubit,
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
              ),
            );
          }
          if (state.error != null && state.items.isEmpty) {
            return HocBongEmptyState(title: state.error!, onRetry: cubit.load);
          }

          final filtered = _filter(state.items, state.filter);
          return Column(
            children: [
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  enablePullDown: true,
                  header: const WaterDropHeader(waterDropColor: AppColors.greenAccent),
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            HocBongEmptyState(title: 'Chưa có học bổng phù hợp'),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return HocBongCard(
                              item: item,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HocBongDetailScreen(
                                    hocBongId: item.id,
                                    repository: repository,
                                  ),
                                ),
                              ).then((_) => cubit.refresh()),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<HocBongModel> _filter(List<HocBongModel> items, String filter) {
    final now = DateTime.now();
    return items.where((e) {
      final isOpen = e.trangThai == 'OPEN' || e.trangThai == 'PUBLISHED';
      final isNotExpired = e.ngayKetThucDangKy == null || e.ngayKetThucDangKy!.isAfter(now);
      final hasNotRegistered = e.trangThaiHoSo == null;
      return isOpen && isNotExpired && hasNotRegistered;
    }).toList();
  }
}
