import 'package:vnu_core/common/app_text_styles.dart';
// import 'package:badges/badges.dart' as BadgeLib;
// import 'package:flutter/material.dart';
// import 'package:vnu_core/common/events.dart';
// import 'package:vnu_core/common/log.dart';
// import 'package:vnu_core/common/utils.dart';
// import 'package:vnu_core/modules/home/vcore_home_view.dart';
// import 'package:vnu_core/modules/profile/views/vcore_profile_view.dart';
// import 'package:vnu_core/repository/data_repository.dart';
// import 'package:vnu_core/screens/vcore_changepass_screen1.dart';
// import 'package:vnu_core/screens/vcore_preview_pdf_screen.dart';
// import 'package:vnu_core/screens/vcore_profile_screen.dart';
// import 'package:vnu_core/screens/vcore_setting_screen.dart';
// import 'package:vnu_core/themes/app_theme.dart';
// import 'package:vnu_noi_tru/nt_globals.dart';
// import 'package:vnu_noi_tru/screens/nt_chitiet_thong_tin_noi_tru_screen.dart';
// import 'package:vnu_noi_tru/screens/nt_dang_ky_noi_tru_screen.dart';
// import 'package:vnu_noi_tru/screens/nt_home_screen.dart';
// import 'package:vnu_noi_tru/screens/nt_left_menu_screen.dart';
// import 'package:vnu_noi_tru/screens/nt_notify_screen.dart';

// class NTTabbarScreen extends StatefulWidget {
//   const NTTabbarScreen({Key? key}) : super(key: key);

//   @override
//   State<NTTabbarScreen> createState() => _NTTabbarScreenState();
// }

// class _NTTabbarScreenState extends State<NTTabbarScreen> {
//   int _selectedIndex = 0;
//   final GlobalKey<ScaffoldState> _key = GlobalKey();

//   static const List<Widget> _widgetOptions = <Widget>[
//     VcoreHomeView(),
//     NTNotifyScreen(),
//     NTHomeScreen(), //New
//     //VCoreMapsScreen(),
//     VcoreProfileView()
//   ];

//   final List<BottomNavigationBarItem> _tabItems = [
//     BottomNavigationBarItem(
//       icon: Container(
//         margin: const EdgeInsets.only(bottom: 5),
//         child: svgAsset(
//           'assets/images/ic_tabbar_home.svg',
//           height: 28,
//           color: AppTheme.colorInActive,
//         ),
//       ),
//       activeIcon: Container(
//         margin: const EdgeInsets.only(bottom: 5),
//         child: svgAsset(
//           'assets/images/ic_tabbar_home.svg',
//           height: 28,
//           color: AppTheme.colorMain,
//         ),
//       ),
//       label: 'Trang chủ',
//     ),

//     // Thông báo
//     BottomNavigationBarItem(
//       icon: StreamBuilder<int>(
//           stream: NtGlobals().unreadCountStream.stream,
//           builder: (context, snapshot) {
//             int count = snapshot.data ?? 0;
//             return BadgeLib.Badge(
//               showBadge: count > 0,
//               badgeStyle: const BadgeLib.BadgeStyle(badgeColor: Colors.red),
//               badgeContent: (snapshot.data ?? 0) <= 0
//                   ? SizedBox()
//                   : Text(
//                       '${snapshot.data}',
//                       style: AppTheme.body2.copyWith(
//                           fontSize: AppFontSizes.extraSmall,
//                           fontWeight: FontWeight.normal,
//                           color: Colors.white),
//                     ),
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 5),
//                 child: svgAsset(
//                   'assets/images/ic_tabbar_notifycation.svg',
//                   height: 28,
//                   color: AppTheme.colorInActive,
//                 ),
//               ),
//             );
//           }),
//       activeIcon: StreamBuilder<int>(
//           stream: NtGlobals().unreadCountStream.stream,
//           builder: (context, snapshot) {
//             int count = snapshot.data ?? 0;
//             return BadgeLib.Badge(
//               showBadge: count > 0,
//               badgeStyle: const BadgeLib.BadgeStyle(badgeColor: Colors.red),
//               badgeContent: Text(
//                 '${snapshot.data}',
//                 style: AppTheme.body2.copyWith(
//                     fontSize: AppFontSizes.extraSmall,
//                     fontWeight: FontWeight.normal,
//                     color: Colors.white),
//               ),
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 5),
//                 child: svgAsset(
//                   'assets/images/ic_tabbar_notifycation.svg',
//                   color: AppTheme.colorMain,
//                   height: 28,
//                 ),
//               ),
//             );
//           }),
//       label: 'Thông báo',
//     ),

//     //---
//     BottomNavigationBarItem(
//       icon: Container(
//         margin: const EdgeInsets.only(bottom: 5),
//         child: svgAsset(
//           'assets/images/ic_tabbar_news.svg',
//           height: 28,
//           color: AppTheme.colorInActive,
//         ),
//       ),
//       activeIcon: Container(
//         margin: const EdgeInsets.only(bottom: 5),
//         child: svgAsset(
//           'assets/images/ic_tabbar_news.svg',
//           height: 28,
//           color: AppTheme.colorMain,
//         ),
//       ),
//       label: 'Tin tức',
//     ),

//     BottomNavigationBarItem(
//       icon: Container(
//           margin: const EdgeInsets.only(bottom: 5),
//           child: const Icon(Icons.account_circle_rounded,
//               color: AppTheme.colorInActive)),
//       activeIcon: Container(
//           margin: const EdgeInsets.only(bottom: 5),
//           child: const Icon(Icons.account_circle_rounded,
//               color: AppTheme.colorMain)),
//       label: 'Cá nhân',
//     ),
//   ];
//   void _onItemTapped(int index) {
//     if (index == 2) {
//       //reset chuyen muc
//       NtGlobals().menuIDChuyenMuc = null;
//       NtGlobals().menuNameChuyenMuc = 'Trang chủ';
//     }
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     globalEvent.on().listen((event) async {
//       if (event is OpenMenuEvent) {
//         _openMenu();
//       }
//     });
//     NtGlobals().fetchMenuList(() {});

//     _checkCaNhanHoa();
//   }

//   _openMenu() {
//     _key.currentState?.openDrawer();
//     NtGlobals().fetchUnreadCount();
//   }

//   _checkCaNhanHoa() async {
//     String? khuVuc = await DataRepository().getSecureSaveKey(kMaKhuVuc);
//     if (!mounted) return;
//     if (khuVuc == null) {
//       Navigator.push(context,
//           MaterialPageRoute(builder: (ctx) => const VCoreSettingScreen()));
//       snackBarWarning(
//           'Bạn hãy cấu hình khu vực học tập để được cập nhật thông tin nhanh chóng hơn.');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     NtGlobals().fetchUnreadCount();
//     return Scaffold(
//       key: _key,
//       drawer: NTLeftMenuScreen(
//         onSelectedMenu: (menu) {
//           if ((menu.screenName ?? '').contains('DangKyNoiTru')) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (ctx) => const NTDangKyNoiTruScreen()));
//           }
//           if ((menu.screenName ?? '').contains('DanhSachTinTuc?ID_ChuyenMuc')) {
//             List<String> _ids = (menu.screenName ?? '').split('=');
//             if (_ids.length > 1) {
//               NtGlobals().menuIDChuyenMuc = int.parse(_ids.last);
//               NtGlobals().menuNameChuyenMuc = menu.tenMenu;
//               logSuccess('menuIDChuyenMuc ---> ${NtGlobals().menuIDChuyenMuc}');
//             }

//             setState(() {
//               _selectedIndex = 0;
//             });
//             globalEvent.fire(FetchMenuSuccess(menu: menu.tenMenu));
//           }
//           if ((menu.screenName ?? '').contains('ChiTietTinTuc?ID_TinTuc')) {
//             List<String> _ids = (menu.screenName ?? '').split('=');
//             if (_ids.length > 1) {
//               String idTinTuc = _ids.last;
//               Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (ctx) => NTChiTietThongTinNoiTruScreen(
//                             tinTucModel: null,
//                             title: menu.tenMenu,
//                             tinTucId: int.parse(idTinTuc),
//                           )));
//             }
//           }
//           if ((menu.screenName ?? '').contains('ChiTietFile?ID_File')) {
//             List<String> ids = (menu.screenName ?? '').split('=');
//             if (ids.length > 1) {
//               String idFile = ids.last;
//               Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (ctx) => VCorePreviewPdfScreen(
//                             title: menu.tenMenu,
//                             fileId: idFile,
//                           )));
//             }
//           }
//           if ((menu.screenName ?? '').contains('ThongTin_CaNhan')) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (ctx) => const VCoreProfileScreen()));
//           }
//           if ((menu.screenName ?? '').contains('DoiMatKhau')) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (ctx) => const VCoreChangePassScreen()));
//           }
//           if ((menu.screenName ?? '').contains('CaNhanHoa')) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (ctx) => const VCoreSettingScreen()));
//           }
//         },
//       ),
//       body: _widgetOptions[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         selectedLabelStyle:
//             AppTheme.caption.copyWith(color: AppTheme.colorMain),
//         unselectedLabelStyle:
//             AppTheme.caption.copyWith(color: AppTheme.colorInActive),
//         items: _tabItems,
//         currentIndex: _selectedIndex,
//         unselectedItemColor: AppTheme.colorInActive,
//         selectedItemColor: AppTheme.colorMain,
//         selectedFontSize: 11,
//         unselectedFontSize: 11,
//         onTap: _onItemTapped,
//       ),
//       // floatingActionButton: Container(
//       //   width: 40,
//       //   height: 40,
//       //   color: Colors.red,
//       // ),
//       // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//     );
//   }
// }
