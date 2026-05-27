import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/empty_data_widget.dart';
import 'package:vnu_core/widgets/error_widget.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';
import 'package:vnu_noi_tru/cubit/nt_news_cubit.dart';
import 'package:vnu_noi_tru/models/nt_danh_sach_thong_bao_model.dart';
import 'package:vnu_noi_tru/nt_globals.dart';
import 'package:vnu_noi_tru/repository/noitru_repository.dart';
import 'package:vnu_noi_tru/screens/nt_dang_ky_noi_tru_screen.dart';
import 'package:vnu_noi_tru/screens/nt_register_process_screen.dart';

class NTNotifyListScreen extends StatefulWidget {
  final String type; //UNREAD - ALL
  const NTNotifyListScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<NTNotifyListScreen> createState() => _NTNotifyListScreenState();
}

class _NTNotifyListScreenState extends State<NTNotifyListScreen> {
  final RefreshController _refreshController = RefreshController();
  late BuildContext hubContext;
  List<DanhSachThongBao> listThongBao = [];
  NtNewsCubit _newsCubit = NtNewsCubit();
  int pageNumber = 1;
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
    _refreshController.refreshCompleted();
    pageNumber = 1;
    listThongBao = [];
    _getData();
  }

  _loadMoreData() {
    pageNumber = pageNumber + 1;
    _getData();
  }

  _getData() {
    _newsCubit.getDanhSachThongBao(
        widget.type == 'UNREAD' ? "0" : "", pageNumber, 20);
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHubWidget(
      contextComplete: (ctx) {
        hubContext = ctx;
      },
      child: BlocListener<NtNewsCubit, NtNewsState>(
        bloc: _newsCubit,
        listener: (context, state) {
          if (state is NtNewsLoadedError) {
            if (pageNumber > 1) {
              snackBarError(state.message);
            }
          }

          if (state is NtNewsShowHub) {
            Utils.showProgress(hubContext);
          }

          if (state is NtNewsDismissHub) {
            Utils.dismissProgress(hubContext);
          }

          if (state is NtNewsLoadedListThongBaoSuccess) {
            if (pageNumber == 1) {
              listThongBao = state.danhSachThongBao;
            } else {
              listThongBao.addAll(state.danhSachThongBao);
            }
            _refreshController.loadComplete();
          }
        },
        child: BlocBuilder<NtNewsCubit, NtNewsState>(
          bloc: _newsCubit,
          builder: (context, state) {
            if (state is NtNewsLoadedError) {
              if (pageNumber == 1) {
                return ErrorRefreshWidget(
                  message: state.message,
                  refreshAction: () {
                    _refreshData();
                  },
                );
              }
            }

            if (state is NtNewsLoading) {
              return const Center(child: LoadingIndicator());
            }
            return SmartRefresher(
              enablePullUp: true,
              controller: _refreshController,
              onRefresh: _refreshData,
              onLoading: _loadMoreData,
              header: const WaterDropHeader(),
              footer: const RefreshFooterWidget(),
              child: listThongBao.isEmpty
                  ? const EmptyDataWidget()
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: listThongBao.length,
                      itemBuilder: (ctx, index) {
                        return _itemNotify(listThongBao[index]);
                      }),
            );
          },
        ),
      ),
    );
  }

  Widget _itemNotify(DanhSachThongBao thongBao) {
    return InkWell(
      onTap: () async {
        await NoiTruRepository().danhDauDaDoc(thongBao.danhSachThongBaoId ?? 0);
        NtGlobals().fetchUnreadCount();
        listThongBao.remove(thongBao);
        setState(() {});
        if ((thongBao.screenName ?? '')
            .toLowerCase()
            .contains('LichSuXuLy'.toLowerCase())) {
          // ignore: use_build_context_synchronously
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => const NTDangKyNoiTruScreen()));
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(width: 2, color: Color(0xffE5E5E5)))),
        child: Row(
          children: [
            //Time
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    thongBao.thoiGianGui ?? '',
                    style: AppTheme.headline6.copyWith(
                        fontWeight: FontWeight.bold, color: Color(0xff00803D)),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    thongBao.ngayGui ?? '',
                    style: AppTheme.body2
                        .copyWith(fontSize: 13, color: Color(0xff979AA5)),
                  ),
                ],
              ),
            ),
            //Info
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User
                    SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            child: const Center(
                              child: Icon(
                                Icons.account_circle,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              '${thongBao.tenNguoiDung} - ${thongBao.soDienThoai}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body2.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: Color(0xff808080)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    //Content
                    Text(
                      thongBao.tieuDe ?? '',
                      style: AppTheme.body2
                          .copyWith(fontSize: 13, color: Colors.black),
                    ),
                    const SizedBox(
                      height: 8,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
