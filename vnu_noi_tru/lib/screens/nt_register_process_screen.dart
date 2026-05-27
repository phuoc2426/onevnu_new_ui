import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/empty_data_widget.dart';
import 'package:vnu_core/widgets/error_widget.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';
import 'package:vnu_noi_tru/cubit/nt_register_cubit.dart';

import '../models/model.dart';

class NTRegisterProcessScreen extends StatefulWidget {
  final int maYeuCau;
  const NTRegisterProcessScreen({super.key, required this.maYeuCau});

  @override
  State<NTRegisterProcessScreen> createState() =>
      _NTRegisterProcessScreenState();
}

class _NTRegisterProcessScreenState extends State<NTRegisterProcessScreen> {
  final RefreshController _refreshController = RefreshController();
  NtRegisterCubit _ntRegisterCubit = NtRegisterCubit();
  late BuildContext hubContext;
  List<DanhSachQuaTrinhXuLy> danhSachQuaTrinhXuLy = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  _refreshData() {
    _ntRegisterCubit.getDanhSachQuaTrinhXuLy(widget.maYeuCau);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Thông tin quá trình xử lý',
      ),
      body: ProgressHubWidget(
        contextComplete: (hub) {
          hubContext = hub;
        },
        child: SmartRefresher(
          enablePullUp: true,
          controller: _refreshController,
          onRefresh: _refreshData,
          // onLoading: _loadMoreData,
          header: const WaterDropHeader(),
          footer: const RefreshFooterWidget(),
          child: BlocBuilder<NtRegisterCubit, NtRegisterState>(
            bloc: _ntRegisterCubit,
            builder: (context, state) {
              if (state is NtRegisterLoadedError) {
                return ErrorRefreshWidget(
                  message: state.message,
                  refreshAction: () {
                    _refreshData();
                  },
                );
              }
              if (state is NtRegisterLoadedListProcessing) {
                danhSachQuaTrinhXuLy =
                    state.danhSachQtxlModel.danhSachQuaTrinhXuLy ?? [];
              }
              return danhSachQuaTrinhXuLy.isEmpty
                  ? const EmptyDataWidget()
                  : ListView.builder(
                      itemCount: danhSachQuaTrinhXuLy.length,
                      itemBuilder: (context, index) {
                        return _itemProcess(danhSachQuaTrinhXuLy[index]);
                      });
            },
          ),
        ),
      ),
    );
  }

  Widget _itemProcess(DanhSachQuaTrinhXuLy process) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration:
          const BoxDecoration(border: Border(bottom: BorderSide(width: 0.25))),
      child: Column(
        children: [
          _itemUser(process),
          const SizedBox(
            height: 15,
          ),
          _itemContent(process.donViXuLy ?? ''),
          const SizedBox(
            height: 6,
          ),
          _itemStatus(process.trangThai ?? '')
        ],
      ),
    );
  }

  Widget _itemUser(DanhSachQuaTrinhXuLy process) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                process.nguoiXuLy ?? '',
                style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold),
              ),
              // const SizedBox(
              //   height: 6,
              // ),
              // Text(
              //   process.donViXuLy ?? '',
              //   style: AppTheme.body2.copyWith(color: Color(0xff777B89)),
              // )
            ],
          ),
        ),
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                (process.thoiGian ?? '   ').split(' ').first,
                style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                (process.thoiGian ?? '   ').split(' ').last,
                style: AppTheme.body2.copyWith(color: Color(0xff777B89)),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _itemContent(String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            height: 16, child: svgAsset('assets/images/ic_arrow_content.svg')),
        const SizedBox(
          width: 6,
        ),
        Text(
          'Nội dung:',
          style: AppTheme.body2
              .copyWith(fontWeight: FontWeight.bold, color: Color(0xff00803D)),
        ),
        const SizedBox(
          width: 6,
        ),
        Expanded(
          child: Text(
            content,
            style: AppTheme.body2.copyWith(),
          ),
        ),
      ],
    );
  }

  Widget _itemStatus(String status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16, child: SizedBox()),
        const SizedBox(
          width: 6,
        ),
        Text(
          'Trạng thái:',
          style: AppTheme.body2
              .copyWith(fontWeight: FontWeight.bold, color: Color(0xff00803D)),
        ),
        const SizedBox(
          width: 6,
        ),
        Expanded(
          child: Text(
            status,
            style: AppTheme.body2.copyWith(color: Color(0xffFF4D00)),
          ),
        ),
      ],
    );
  }
}
