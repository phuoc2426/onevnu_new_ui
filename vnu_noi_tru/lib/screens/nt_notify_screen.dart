import 'package:flutter/material.dart';
import 'package:vnu_core/common/events.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_noi_tru/nt_globals.dart';
import 'package:vnu_noi_tru/screens/nt_notify_list_screen.dart';
import 'package:vnu_core/widgets/navi_item_action.dart';

class NTNotifyScreen extends StatefulWidget {
  const NTNotifyScreen({Key? key}) : super(key: key);

  @override
  State<NTNotifyScreen> createState() => _NTNotifyScreenState();
}

class _NTNotifyScreenState extends State<NTNotifyScreen> {
  @override
  Widget build(BuildContext context) {
    NtGlobals().fetchUnreadCount();

    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Thông báo',
        leftAction: IconButton(
            onPressed: () {
              globalEvent.fire(OpenMenuEvent());
            },
            icon: const Icon(Icons.menu)),
        // rightActions: [
        //   StreamBuilder<int>(
        //       stream: NtGlobals().unreadCountStream.stream,
        //       builder: (context, snapshot) {
        //         return NaviItemAction(
        //           icon: svgAction('assets/images/ic_navi_bell.svg',
        //               color: Colors.white, width: 18, action: () {}),
        //           count: snapshot.data,
        //         );
        //       }),
        // ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: AppTheme.colorMain,
              unselectedLabelColor: const Color(0xff879ABF),
              indicatorColor: const Color(0xff003392),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTheme.body1.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(
                  text: 'Chưa xem',
                ),
                Tab(
                  text: 'Tất cả',
                ),
              ],
            ),
            // content
            const Expanded(
                child: TabBarView(children: [
              NTNotifyListScreen(type: 'UNREAD'),
              NTNotifyListScreen(type: 'ALL')
            ]))
          ],
        ),
      ),
    );
  }
}
