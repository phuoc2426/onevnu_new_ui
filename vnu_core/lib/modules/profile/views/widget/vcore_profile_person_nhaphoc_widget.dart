import 'package:flutter/material.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';

import 'vcore_profile_info_header_widget.dart';
import 'vcore_profile_textfield_widget.dart';

class VcoreProfilePersonNhapHocWidget extends StatefulWidget {
  const VcoreProfilePersonNhapHocWidget({super.key});

  @override
  State<VcoreProfilePersonNhapHocWidget> createState() =>
      _VcoreProfilePersonNhapHocWidgetState();
}

class _VcoreProfilePersonNhapHocWidgetState
    extends State<VcoreProfilePersonNhapHocWidget> {
  String bacHoc = '';
  String hinhThucDaoTao = '';
  String chuongTrinhDaoTao = '';
  String khoa = '';
  String lopQuanLy = '';
  String truong1 = '';
  String nganh1 = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadInfo();
  }

  _loadInfo() async {
    lopQuanLy = Globals().lopDaoTaoModel.value?.ten ?? '';

    try {
      var response = await ApiRepository().getDataChuongTrinhDaoTao(
          Globals().thongTinSinhVienModel.value?.idChuongTrinhDaoTao,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          Globals().thongTinSinhVienModel.value?.idBacDaoTao,
          Globals().thongTinSinhVienModel.value?.idHeDaoTao,
          Globals().thongTinSinhVienModel.value?.idNganhDaoTao,
          Globals().thongTinSinhVienModel.value?.idNienKhoaDaoTao);
      if (response.isNotEmpty) {
        setState(() {
          chuongTrinhDaoTao = response.first.ten ?? '';
        });
      }
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataBacDaoTao(
        Globals().thongTinSinhVienModel.value?.idBacDaoTao,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
      );
      if (response.isNotEmpty) {
        setState(() {
          bacHoc = response.first.ten ?? '';
        });
      }
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataHeDaoTao(
        Globals().thongTinSinhVienModel.value?.idHeDaoTao,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        Globals().thongTinSinhVienModel.value?.idBacDaoTao,
      );
      if (response.isNotEmpty) {
        setState(() {
          hinhThucDaoTao = response.first.ten ?? '';
        });
      }
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataNienKhoaDaoTao(
        Globals().thongTinSinhVienModel.value?.idNienKhoaDaoTao,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        Globals().thongTinSinhVienModel.value?.idBacDaoTao,
      );
      if (response.isNotEmpty) {
        setState(() {
          khoa =
              '${response.first.namBatDau ?? ''} - ${response.first.namKetThuc ?? ''}';
        });
      }
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDonVi(
        Globals().currentUserModel.value?.guidDonVi ?? '',
      );
      setState(() {
        truong1 = response.tenDonVi ?? '';
      });
    } catch (e) {
      logError(e.toString());
    }

    if ((Globals().thongTinSinhVienModel.value?.idNganhDaoTao ?? '')
        .isNotEmpty) {
      try {
        var response = await ApiRepository().getDataNganhDaoTao(
            Globals().thongTinSinhVienModel.value?.idNganhDaoTao,
            Globals().currentUserModel.value?.guidDonVi ?? '',
            Globals().thongTinSinhVienModel.value?.idBacDaoTao);
        if (response.isNotEmpty) {
          setState(() {
            nganh1 = response.first.ten ?? '';
          });
        }
      } catch (e) {
        logError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const itemSpace = 16.0;
    return Container(
        color: Colors.white,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VcoreProfileInfoHeaderWidget(title: 'Thông tin nhập học'),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                //Ngày vào đảng
                Row(children: [
                  //
                  Expanded(
                      child: VcoreProfileTextFieldWidget(
                    title: 'Bậc',
                    hintText: bacHoc,
                    value: bacHoc,
                    isDisable: true,
                    onSubmitted: (text) {},
                  )),
                  spaceWidth(10),

                  Expanded(
                      child: VcoreProfileTextFieldWidget(
                    title: 'Hình thức đào tạo',
                    hintText: hinhThucDaoTao,
                    value: hinhThucDaoTao,
                    isDisable: true,
                    onSubmitted: (text) {},
                  )),
                ]),
                spaceHeight(itemSpace),

                //
                VcoreProfileTextFieldWidget(
                  title: 'Chương trình đào tạo',
                  hintText: chuongTrinhDaoTao,
                  value: chuongTrinhDaoTao,
                  isDisable: true,
                  onSubmitted: (text) {},
                ),
                spaceHeight(itemSpace),

                // Khoa - Lop
                Row(children: [
                  //
                  Expanded(
                      child: VcoreProfileTextFieldWidget(
                    title: 'Khóa',
                    hintText: khoa,
                    value: khoa,
                    isDisable: true,
                    onSubmitted: (text) {},
                  )),
                  spaceWidth(10),

                  Expanded(
                      child: VcoreProfileTextFieldWidget(
                    title: 'Lớp quản lý',
                    hintText: lopQuanLy,
                    value: lopQuanLy,
                    isDisable: true,
                    onSubmitted: (text) {},
                  )),
                ]),
                spaceHeight(itemSpace),

                //
                VcoreProfileTextFieldWidget(
                  title: 'Trường 1',
                  hintText: truong1,
                  value: truong1,
                  isDisable: true,
                  onSubmitted: (text) {},
                ),
                spaceHeight(itemSpace),

                //
                VcoreProfileTextFieldWidget(
                  title: 'Ngành 1',
                  hintText: nganh1,
                  value: nganh1,
                  isDisable: true,
                  onSubmitted: (text) {},
                ),
              ]))
        ]));
  }
}
