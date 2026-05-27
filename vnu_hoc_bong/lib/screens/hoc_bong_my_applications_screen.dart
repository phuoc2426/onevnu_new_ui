import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/app_colors.dart';

import '../common/hoc_bong_date_utils.dart';
import '../common/hoc_bong_status.dart';
import '../cubit/hoc_bong_ho_so_cubit.dart';
import '../cubit/hoc_bong_states.dart';
import '../models/hoc_bong_models.dart';
import '../repository/hoc_bong_repository.dart';
import '../widgets/hoc_bong_empty_state.dart';
import '../widgets/hoc_bong_screen_shell.dart';
import '../widgets/hoc_bong_status_chip.dart';
import 'hoc_bong_application_detail_screen.dart';

class HocBongMyApplicationsScreen extends StatefulWidget {
  final HocBongRepository repository;

  const HocBongMyApplicationsScreen({super.key, required this.repository});

  @override
  State<HocBongMyApplicationsScreen> createState() => _HocBongMyApplicationsScreenState();
}

class _HocBongMyApplicationsScreenState extends State<HocBongMyApplicationsScreen> {
  late final HocBongHoSoCubit cubit;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    cubit = HocBongHoSoCubit(widget.repository)..loadMine();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    cubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await cubit.loadMine();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return HocBongScreenShell(
      title: 'Hồ sơ học bổng của tôi',
      body: BlocBuilder<HocBongHoSoCubit, HocBongHoSoState>(
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
            return HocBongEmptyState(title: state.error!, onRetry: cubit.loadMine);
          }

          final items = state.items.where((e) => e.hocBongId == null).toList();
          return Column(
            children: [
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  enablePullDown: true,
                  header: const WaterDropHeader(waterDropColor: AppColors.greenAccent),
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            HocBongEmptyState(title: 'Bạn chưa có hồ sơ học bổng'),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24, top: 16),
                          itemCount: items.length,
                          itemBuilder: (context, index) => _ApplicationCard(
                            item: items[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HocBongApplicationDetailScreen(
                                  hoSoId: items[index].id,
                                  repository: widget.repository,
                                ),
                              ),
                            ).then((_) => cubit.loadMine()),
                          ),
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

class _ApplicationCard extends StatelessWidget {
  final HocBongHoSoModel item;
  final VoidCallback onTap;
  const _ApplicationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(item.tenHocBong ?? 'Hồ sơ học bổng', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Ngày gửi: ${HocBongDateUtils.formatDateTime(item.ngayGui ?? item.ngayLuuNhap)}'),
        trailing: HocBongStatusChip(
          status: item.trangThai,
          label: item.trangThaiText ?? HocBongStatusText.application(item.trangThai),
        ),
      ),
    );
  }
}


