import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/extensions/iterables.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_noi_tru/cubit/nt_register_cubit.dart';
import 'package:vnu_noi_tru/screens/nt_register_process_screen.dart';
import 'package:vnu_noi_tru/widgets/nt_container_dropbox_widget.dart';
import 'package:vnu_noi_tru/widgets/nt_file_da_upload_widget.dart';
import 'package:vnu_noi_tru/widgets/nt_register_payment_info.dart';
import '../models/model.dart';
import '../widgets/nt_dropbox_widget.dart';
import '../widgets/nt_register_cmnd_widget.dart';

class NTDangKyNoiTruScreen extends StatefulWidget {
  const NTDangKyNoiTruScreen({super.key});

  @override
  State<NTDangKyNoiTruScreen> createState() => _NTDangKyNoiTruScreenState();
}

class _NTDangKyNoiTruScreenState extends State<NTDangKyNoiTruScreen> {
  NtRegisterCubit _ntRegisterCubit = NtRegisterCubit();
  late BuildContext hubContext;
  List<DanhSachDoiTuongUuTien> danhSachDoiTuongUuTien = [];
  List<DanhSachDotDangKyLuuTru> danhSachDotDangKyLuuTru = [];
  List<DanhSachLoaiPhong> danhSachLoaiPhong = [];
  List<DanhSachTrungTamLuuTru> danhSachTrungTamLuuTru = [];

  List<DanhSachDoiTuongUuTien> doiTuongUuTiens = [];
  DanhSachDotDangKyLuuTru? dotDangKyLuuTru;
  DanhSachTrungTamLuuTru? trungTamLuuTru;
  DanhSachLoaiPhong? loaiPhong;
  List<NtFileMinhChungModel> fileMinhChung = [];

  /*
  *   Phiếu đã đăng ký
  */
  PhieuDangKyNoiTruModel? phieuDangKyNoiTruModel;
  bool isLoadedPhieuDangKy = false;
  StreamController<int> streamController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    _getDanhSachDoiTuongUuTien();
    _getDanhSachDotDangKy();
    _getDanhSachTrungTamLuuTru();
    _getDanhSachPhieuDangKy();
  }

  _getDanhSachDoiTuongUuTien() {
    _ntRegisterCubit.getDanhSachDoiTuongUuTien();
  }

  _getDanhSachDotDangKy() {
    _ntRegisterCubit.getDanhSachDotDangKy();
  }

  _getDanhSachTrungTamLuuTru() {
    _ntRegisterCubit.getDanhSachTrungTamLuuTru();
  }

  _getDanhSachPhongCuaTrungTamLuuTru() {
    if (trungTamLuuTru?.id == null) return;
    //Reset
    danhSachLoaiPhong = [];
    loaiPhong = null;

    _ntRegisterCubit.getDanhSachPhongCuaTrungTam(trungTamLuuTru!.id!);
    logInfo('_getDanhSachPhongCuaTrungTamLuuTru');
  }

  _getDanhSachPhieuDangKy() {
    _ntRegisterCubit.getDanhSachPhieuDangKy();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Đăng ký nội trú',
        leftAction: svgAction('assets/images/ic_navi_back.svg', action: () {
          Navigator.pop(context);
        }),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ProgressHubWidget(
          contextComplete: (ctx) {
            hubContext = ctx;
          },
          child: BlocListener<NtRegisterCubit, NtRegisterState>(
            bloc: _ntRegisterCubit,
            listener: (context, state) {
              if (state is NtRegisterShowHub) {
                Utils.showProgress(hubContext);
              }

              if (state is NtRegisterDismissHub) {
                Utils.dismissProgress(hubContext);
              }

              if (state is NtRegisterLoadPhieuDangKySuccess) {
                isLoadedPhieuDangKy = true;
                if (state.phieuDangky.isNotEmpty) {
                  phieuDangKyNoiTruModel = state.phieuDangky.first;
                  doiTuongUuTiens =
                      phieuDangKyNoiTruModel?.danhSachDoiTuongUuTien ?? [];
                  dotDangKyLuuTru = phieuDangKyNoiTruModel?.dotDangKy;
                  trungTamLuuTru = phieuDangKyNoiTruModel?.trungTamLuuTru;
                  loaiPhong = phieuDangKyNoiTruModel?.loaiPhong;
                  if (loaiPhong != null) {
                    danhSachLoaiPhong.add(loaiPhong!);
                  }
                }
              }

              if (state is NtRegisterLoadedListDoiTuongUuTien) {
                danhSachDoiTuongUuTien =
                    state.danhSachDoiTuongUuTienModel.danhSachDoiTuongUuTien ??
                        [];
                // if (isLoadedPhieuDangKy && phieuDangKyNoiTruModel != null) {
                //   doiTuongUuTien =
                //       phieuDangKyNoiTruModel?.danhSachDoiTuongUuTien?.first;
                //   //_findDefaultThongTinDangKy();
                // }
                // if (doiTuongUuTien == null &&
                //     danhSachDoiTuongUuTien.isNotEmpty) {
                //   doiTuongUuTien = danhSachDoiTuongUuTien.first;
                // }
                logSuccess(danhSachDoiTuongUuTien.length.toString());
              }

              if (state is NtRegisterLoadedListTrungTamLuuTru) {
                danhSachTrungTamLuuTru =
                    state.danhSachTrungTamLuuTruModel.danhSachTrungTamLuuTru ??
                        [];
                // if (trungTamLuuTru == null &&
                //     danhSachTrungTamLuuTru.isNotEmpty) {
                //   trungTamLuuTru = danhSachTrungTamLuuTru.first;
                //   _getDanhSachPhongCuaTrungTamLuuTru();
                // }
              }

              if (state is NtRegisterLoadedListDanhSachDotDangKy) {
                danhSachDotDangKyLuuTru = state
                        .danhSachDotDangKyLuuTruModel.danhSachDotDangKyLuuTru ??
                    [];
                // if (dotDangKyLuuTru == null &&
                //     danhSachDotDangKyLuuTru.isNotEmpty) {
                //   dotDangKyLuuTru = danhSachDotDangKyLuuTru.first;
                // }
              }

              if (state is NtRegisterLoadedListDanhSachLoaiPhong) {
                danhSachLoaiPhong =
                    state.danhSachPhongModel.danhSachLoaiPhong ?? [];
                // if (loaiPhong == null && danhSachLoaiPhong.isNotEmpty) {
                //   loaiPhong = danhSachLoaiPhong.first;
                // }
              }

              if (state is NtRegisterLoadedError) {
                snackBarError(state.message);
              }

              if (state is NtRegisterSavedSuccess) {
                Navigator.pop(context);
                snackBarSuccess(state.message);
              }
            },
            child: BlocBuilder<NtRegisterCubit, NtRegisterState>(
              bloc: _ntRegisterCubit,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(
                      top: 20, left: 10, right: 10, bottom: 5),
                  child: Column(
                    children: [
                      Expanded(
                          child: NestedScrollView(
                              headerSliverBuilder:
                                  (context, innerBoxIsScrolled) {
                                return [
                                  SliverToBoxAdapter(
                                    child: NtContainerDropboxWidget(
                                      title: 'Chọn đối tượng ưu tiên',
                                      value: doiTuongUuTiens
                                          .map((e) => e.tenDoiTuongUuTien ?? '')
                                          .join('\n\n'),
                                      onSelecte: () {
                                        _pickDoiTuongUuTien();
                                      },
                                      activeSelect:
                                          phieuDangKyNoiTruModel == null,
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Visibility(
                                      visible: phieuDangKyNoiTruModel == null,
                                      child: NTRegisterCmndWidget(
                                        prefixDTUU: doiTuongUuTiens.isNotEmpty
                                            ? doiTuongUuTiens.first.prefix
                                            : null,
                                        onChangeFiles: (files) {
                                          logSuccess(
                                              'ONchange file Minh Chung...');
                                          fileMinhChung = files;
                                        },
                                      ),
                                    ),
                                  ),
                                  //Anh
                                  SliverToBoxAdapter(
                                    child: Visibility(
                                      visible: (phieuDangKyNoiTruModel
                                                  ?.danhSachFileDaUpLoad ??
                                              [])
                                          .isNotEmpty,
                                      child: NtFileDaUploadWidget(
                                          listFile: phieuDangKyNoiTruModel
                                                  ?.danhSachFileDaUpLoad ??
                                              []),
                                    ),
                                  ),
                                  //
                                  SliverToBoxAdapter(
                                    child: NTDropboxWidget(
                                      title: 'Đợt đăng ký',
                                      value: dotDangKyLuuTru?.tenDotDangKy,
                                      listOption: danhSachDotDangKyLuuTru
                                          .map((e) => e.tenDotDangKy ?? '')
                                          .toList(),
                                      onSelected: (value, index) {
                                        setState(() {
                                          dotDangKyLuuTru =
                                              danhSachDotDangKyLuuTru[index];
                                        });
                                      },
                                      activeSelect:
                                          phieuDangKyNoiTruModel == null,
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: NTDropboxWidget(
                                      title: 'Chọn ký túc xá',
                                      value: trungTamLuuTru?.tenTrungTamLuuTru,
                                      listOption: danhSachTrungTamLuuTru
                                          .map((e) => e.tenTrungTamLuuTru ?? '')
                                          .toList(),
                                      onSelected: (value, index) {
                                        setState(() {
                                          trungTamLuuTru =
                                              danhSachTrungTamLuuTru[index];
                                          _getDanhSachPhongCuaTrungTamLuuTru();
                                        });
                                      },
                                      activeSelect:
                                          phieuDangKyNoiTruModel == null,
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: NTDropboxWidget(
                                      title: 'Chọn loại phòng',
                                      value: loaiPhong?.tenLoaiPhong,
                                      listOption: danhSachLoaiPhong
                                          .map((e) => e.tenLoaiPhong ?? '')
                                          .toList(),
                                      onSelected: (value, index) {
                                        setState(() {
                                          loaiPhong = danhSachLoaiPhong[index];
                                        });
                                      },
                                      activeSelect:
                                          phieuDangKyNoiTruModel == null,
                                    ),
                                  ),
                                ];
                              },
                              body: Visibility(
                                  visible: loaiPhong != null,
                                  child: NTRegisterPaymentInfoWidget(
                                    loaiPhong: loaiPhong,
                                  )))),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: phieuDangKyNoiTruModel == null,
                            child: BlueButton(
                              title: 'Lưu',
                              action: () {
                                _excDangKyNoiTru();
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Visibility(
                            visible: phieuDangKyNoiTruModel != null,
                            child: WhiteButton(
                              title: 'Quá trình xử lý',
                              action: () {
                                if (phieuDangKyNoiTruModel?.id == null) return;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (ctx) =>
                                            NTRegisterProcessScreen(
                                              maYeuCau:
                                                  phieuDangKyNoiTruModel!.id!,
                                            )));
                              },
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  _pickDoiTuongUuTien() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return StreamBuilder<int>(
              stream: streamController.stream,
              builder: (context, snapshot) {
                return ListView.builder(
                    itemCount: danhSachDoiTuongUuTien.length,
                    itemBuilder: (ctx, index) {
                      return _itemDoiTuongUuTien(danhSachDoiTuongUuTien[index]);
                    });
              });
        });
  }

  Widget _itemDoiTuongUuTien(DanhSachDoiTuongUuTien object) {
    return InkWell(
      onTap: () {
        // if (doiTuongUuTiens.contains(object)) {
        //   doiTuongUuTiens.remove(object);
        // } else {
        //   doiTuongUuTiens.add(object);
        // }
        //Sua thanh chon 1
        doiTuongUuTiens = [object];
        setState(() {});
        streamController.add(0);
      },
      child: Row(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(object.tenDoiTuongUuTien ?? ''),
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              doiTuongUuTiens.contains(object)
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: AppTheme.colorMain,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }

  _excDangKyNoiTru() {
    if (dotDangKyLuuTru == null ||
        trungTamLuuTru == null ||
        loaiPhong == null) {
      snackBarError('Bạn cần chọn đầy đủ thông tin để gửi đăng ký nội trú');
      return;
    }
    logSuccess('start _excDangKyNoiTru');
    List<int> fileIds = [];
    fileMinhChung.forEach((element) {
      if (element.fileMinhChungId != null) {
        fileIds.add(element.fileMinhChungId!);
      }
    });
    _ntRegisterCubit.dangKyNoitru(doiTuongUuTiens, dotDangKyLuuTru!,
        trungTamLuuTru!, loaiPhong!, fileIds);
  }
}
