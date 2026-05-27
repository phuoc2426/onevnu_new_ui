import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_noi_tru/common/enum.dart';
import 'package:vnu_noi_tru/data/noitru_response.dart';
import 'package:vnu_noi_tru/nt_globals.dart';
import 'package:vnu_noi_tru/repository/noitru_repository.dart';

import '../models/model.dart';

class NTLeftMenuScreen extends StatefulWidget {
  final Function(DanhSachMenu menuScreen)? onSelectedMenu;
  const NTLeftMenuScreen({super.key, this.onSelectedMenu});

  @override
  State<NTLeftMenuScreen> createState() => _NTLeftMenuScreenState();
}

class _NTLeftMenuScreenState extends State<NTLeftMenuScreen> {
  String version = '';
  @override
  void initState() {
    super.initState();
    _loadMenu();
    _getVersion();
  }

  _loadMenu() {
    logInfo('Load menu');
    Future.delayed(Duration(seconds: 1), () async {
      try {
        var menu = await NoiTruRepository().getDanhSachMenu();
        NtGlobals().menuModel = menu.data;
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        snackBarError(e.toString());
      }
    });
  }

  _getVersion() {
    Future.delayed(const Duration(milliseconds: 250), () async {
      version = await Utils.version();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff006525),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 10),
                      height: 70,
                      child: Row(
                        children: [
                          svgAsset('assets/images/ic_logo_vnu_white.svg',
                              width: 50),
                          Expanded(
                            child: Align(
                              // alignment: ,
                              child: Text(
                                'OneVNU',
                                style: AppTheme.headline6
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 10),
                      color: Color(0xff158D41),
                      width: double.infinity,
                      height: 1,
                    ),

                    Column(
                      children: _buildMenu(),
                    ),

                    /// Thong tin ca nhan
                    _itemMenu('Cá nhân hoá',
                        iconFlutter: '0xf0164', isHeader: true, action: () {
                      _onSelectedMenu(DanhSachMenu(screenName: 'CaNhanHoa'));
                    }),

                    /// Thong tin ca nhan
                    _itemMenu('Thông tin cá nhân', isHeader: true, action: () {
                      _onSelectedMenu(
                          DanhSachMenu(screenName: 'ThongTin_CaNhan'));
                    }),

                    /// Doi mat khau
                    _itemMenu('Đổi mật khẩu', isHeader: true, action: () {
                      _onSelectedMenu(DanhSachMenu(screenName: 'DoiMatKhau'));
                    }),

                    /// Dang xuat
                    Visibility(
                      visible: VnuCore().isLogin(),
                      child: _itemMenu('Đăng xuất', isHeader: true, action: () {
                        Utils.showAlertDialog(context, "Thông báo",
                            "Bạn thật sự muốn thoát ứng dụng?",
                            okStr: "CÓ", cancelStr: "KHÔNG", callBackOK: () {
                          Globals().clearSession();
                          VnuCore().gotoLogin();
                        });
                        logInfo('Logout');
                      }),
                    ),
                  ],
                ),
              ),
            ),

            //
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Phiên bản: $version',
                style: AppTheme.body2.copyWith(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildMenu() {
    List<Widget> danhSachMenu = [];
    for (DanhSachMenu element in (NtGlobals().menuModel?.danhSachMenu ?? [])) {
      danhSachMenu.add(_itemMenu(element.tenMenu ?? '',
          icon: 'assets/images/ic_menu_file.svg', isHeader: true, action: () {
        if (element.screenName != "#" &&
            (element.screenName ?? '').isNotEmpty) {
          _onSelectedMenu(element);
        }
      }));
      for (DanhSachMenu child in (element.danhSachMenuCon ?? [])) {
        danhSachMenu
            .add(_itemMenu(child.tenMenu ?? '', isHeader: false, action: (() {
          _onSelectedMenu(child);
        })));
      }
    }
    return danhSachMenu;
  }

  Widget _itemMenu(String title,
      {String? icon,
      String? iconFlutter,
      bool? isHeader,
      VoidCallback? action}) {
    return InkWell(
      onTap: action == null
          ? null
          : () {
              if (action != null) {
                action();
              }
            },
      child: Container(
        padding: const EdgeInsets.only(left: 8, top: 12, bottom: 12),
        child: Row(
          children: [
            SizedBox(
                width: 30,
                child: icon != null
                    ? svgAsset(icon)
                    : (iconFlutter != null
                        ? Icon(
                            IconData(iconFlutter.parseImageInt(),
                                fontFamily: 'MaterialIcons'),
                            color: Colors.white,
                            size: 20,
                          )
                        : const SizedBox())),
            const SizedBox(
              width: 10,
            ),
            Text(
              title,
              style: AppTheme.body2.copyWith(
                  color: Colors.white,
                  fontWeight:
                      isHeader == true ? FontWeight.bold : FontWeight.normal),
            )
          ],
        ),
      ),
    );
  }

  _onSelectedMenu(DanhSachMenu menu) {
    Navigator.pop(context);
    if (widget.onSelectedMenu != null) {
      widget.onSelectedMenu!(menu);
    }
  }
}
