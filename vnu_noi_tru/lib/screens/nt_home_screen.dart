import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/events.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/widgets/empty_data_widget.dart';
import 'package:vnu_core/widgets/error_widget.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';
import 'package:vnu_noi_tru/cubit/nt_news_cubit.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/nt_globals.dart';
import 'package:vnu_noi_tru/screens/nt_chitiet_thong_tin_noi_tru_screen.dart';

import '../widgets/nt_noitru_item_widget.dart';

class NTHomeScreen extends StatefulWidget {
  const NTHomeScreen({Key? key}) : super(key: key);

  @override
  State<NTHomeScreen> createState() => _NTHomeScreenState();
}

class _NTHomeScreenState extends State<NTHomeScreen> {
  final RefreshController _refreshController = RefreshController();
  late BuildContext hubContext;

  NtNewsCubit _cubit = NtNewsCubit();

  List<NtTinTucModel> _listTintuc = [];
  int? idChuyenMuc;
  int pageSize = 20;
  int pageNumber = 1;
  @override
  void initState() {
    super.initState();
    idChuyenMuc = NtGlobals().menuIDChuyenMuc;
    _refreshData();
    globalEvent.on().listen((event) async {
      if (event is FetchMenuSuccess) {
        logSuccess(event.menu ?? 'Trangg chu');

        setState(() {});
        if (idChuyenMuc != NtGlobals().menuIDChuyenMuc) {
          idChuyenMuc = NtGlobals().menuIDChuyenMuc;
          _refreshData();
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  _refreshData() {
    _refreshController.refreshCompleted();
    _listTintuc = [];
    pageNumber = 1;
    _cubit.getDanhSachTinTuc(idChuyenMuc, pageNumber, pageSize);
  }

  _loadMoreData() {
    pageNumber += 1;
    _cubit.getDanhSachTinTuc(idChuyenMuc, pageNumber, pageSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: NaviWidget(
          titleStr: NtGlobals().menuNameChuyenMuc ?? 'Trang chủ',
          leftAction: IconButton(
              onPressed: () {
                globalEvent.fire(OpenMenuEvent());
              },
              icon: Icon(Icons.menu)),
        ),
        backgroundColor: Color.fromRGBO(246, 249, 254, 1),
        body: ProgressHubWidget(
          contextComplete: (ctx) {
            hubContext = ctx;
          },
          child: BlocListener<NtNewsCubit, NtNewsState>(
            bloc: _cubit,
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

              if (state is NtNewsLoadedListSuccess) {
                if (pageNumber == 1) {
                  _listTintuc = state.danhSachTinTuc;
                } else {
                  _listTintuc.addAll(state.danhSachTinTuc);
                }
                _refreshController.loadComplete();
              }
            },
            child: BlocBuilder<NtNewsCubit, NtNewsState>(
              bloc: _cubit,
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
                return Container(
                  margin: const EdgeInsets.all(20),
                  child: SmartRefresher(
                    enablePullUp: true,
                    controller: _refreshController,
                    onRefresh: _refreshData,
                    onLoading: _loadMoreData,
                    header: const WaterDropHeader(),
                    footer: const RefreshFooterWidget(),
                    child: _listTintuc.isEmpty
                        ? const EmptyDataWidget()
                        : ListView.builder(
                            itemCount: _listTintuc.length,
                            itemBuilder: (context, index) {
                              return NTNoiTruItemWidget(
                                tinTucModel: _listTintuc[index],
                                onSelected: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (ctx) =>
                                              NTChiTietThongTinNoiTruScreen(
                                                tinTucModel: _listTintuc[index],
                                                tinTucId: _listTintuc[index]
                                                    .tinnTucModelId,
                                              )));
                                },
                              );
                            }),
                  ),
                );
              },
            ),
          ),
        ));
  }
}
