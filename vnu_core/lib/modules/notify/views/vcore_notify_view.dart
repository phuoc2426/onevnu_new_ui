import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'vcore_notify_list_view.dart';

class VcoreNotifyView extends StatelessWidget {
  const VcoreNotifyView({super.key});

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Thông báo',
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              height: 46,
              child: TabBar(
                labelColor: AppTheme.colorMain,
                unselectedLabelColor: AppColors.dropdownBorder,
                indicatorColor: AppColors.darkBlueAccent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle:
                    AppTheme.body1.copyWith(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(
                    text: 'Chưa xem',
                  ),
                  Tab(
                    text: 'Tất cả',
                  ),
                ],
              ),
            ),

            //
            const Expanded(
              child: TabBarView(
                children: [
                  VcoreNotifyListView(
                    status: NotifyStatus.unRead,
                  ),
                  VcoreNotifyListView(status: NotifyStatus.all),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
