import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:vnu_core/common/events.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_view.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';

import '../../home/vcore_home_view_v3.dart';
import '../../news/views/vcore_news_view_v3.dart';
import '../../profile/views/vcore_profile_view.dart';
import '../../system_news/views/vcore_system_news_view.dart';

class VcoreTabbarView extends StatefulWidget {
  const VcoreTabbarView({super.key});

  @override
  State<VcoreTabbarView> createState() => _VcoreTabbarViewState();
}

class _VcoreTabbarViewState extends State<VcoreTabbarView> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  static List<Widget> get _widgetOptions => const <Widget>[
        VcoreHomeViewV3(),
        VcoreNewsViewV3(),
        VcoreSystemNewsView(),
        VcoreProfileView(),
      ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();

    // Firebase token
    try {
      FirebaseMessaging.instance.getToken().then(
            (firebaseToken) => VnuCore().addFirebaseToken(firebaseToken),
          );
    } catch (e) {
      logError(e.toString());
    }

    Globals().fetchUnreadCount();

    Future.delayed(Duration.zero, () {
      _loadAndRefreshStartInfo();
    });

    globalEvent.on().listen((event) async {
      if (event is TokenExpiredEvent) {
        Globals().clearSession(deleteUserLogin: false);
        VnuCore().gotoLogin();
      }
    });
  }

  Future<void> _loadAndRefreshStartInfo() async {
    try {
      ApiRepository()
          .getConfig()
          .then((domain) => ServicesUrl().baseUrlFileDownload = domain);
    } catch (e) {
      logError(e.toString());
    }

    try {
      ApiRepository().getCurrentUser().then((user) {
        Globals().currentUserModel.value = user;
      });
    } catch (e) {
      logError(e.toString());
    }

    try {
      ApiRepository().getTopics().then((topic) {
        _subscribeTopics(topic);
      });
    } catch (e) {
      logError(e.toString());
    }

    await Globals().refreshStudentInfo();
    try {
      if (Globals().thongTinSinhVienModel.value != null) {
        var response = await ApiRepository().getDataLopDaoTao(
          Globals().thongTinSinhVienModel.value?.idLopDaoTao,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          Globals().thongTinSinhVienModel.value?.idBacDaoTao,
          Globals().thongTinSinhVienModel.value?.idHeDaoTao,
          Globals().thongTinSinhVienModel.value?.idNganhDaoTao,
          Globals().thongTinSinhVienModel.value?.idNienKhoaDaoTao,
          Globals().thongTinSinhVienModel.value?.idChuongTrinhDaoTao,
        );
        if (response.isNotEmpty) {
          Globals().lopDaoTaoModel.value = response.first;
        } else {
          logError('getDataLopDaoTao --> empty');
        }
      }
    } catch (e) {
      logError('getDataLopDaoTao --> ERROR');
      logError(e.toString());
    }

    try {
      if (Globals().thongTinSinhVienModel.value != null) {
        var response = await ApiRepository().getDataNienKhoaDaoTao(
          Globals().thongTinSinhVienModel.value?.idNienKhoaDaoTao,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          Globals().thongTinSinhVienModel.value?.idBacDaoTao,
        );
        if (response.isNotEmpty) {
          Globals().nienKhoaDaoTaoModel.value = response.first;
        } else {
          logError('getDataNienKhoaDaoTao --> empty');
        }
      }
    } catch (e) {
      logError('getDataNienKhoaDaoTao --> ERROR');
      logError(e.toString());
    }
  }

  Future<void> _subscribeTopics(List<String> topics) async {
    ServicesUrl().topics = topics;

    await Future.forEach(topics, (topic) async {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    });

    await Future.forEach(topics, (topic) async {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      extendBody: true,
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildSalomonBottomNavBar(),
    );
  }

  Widget _buildSalomonBottomNavBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SalomonBottomBar(
          currentIndex: _selectedIndex,
          itemPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          onTap: (index) {
            if (index != _selectedIndex) {
              setState(() => _selectedIndex = index);
            }
          },
          selectedItemColor: const Color(0xFF16A34A),
          unselectedItemColor: Colors.grey.shade400,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_rounded, size: 22),
              title: const Text(
                "Trang chủ",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              selectedColor: const Color(0xFF16A34A),
            ),

            SalomonBottomBarItem(
              icon: const Icon(Icons.newspaper, size: 22),
              title: const Text(
                "Tin tức",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              selectedColor: const Color(0xFFEA580C),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.campaign, size: 22),
              title: const Text(
                "Tin hệ thống",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              selectedColor: const Color(0xFF0284C7),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.person_outline_rounded, size: 22),
              title: const Text(
                "Cá nhân",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              selectedColor: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }
}
