import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/modules/profile/views/forgot_password_v2/vcore_forgot_pass_email_tab_v2.dart';
import 'package:vnu_core/modules/profile/views/forgot_password_v2/vcore_forgot_pass_support_tab_v2.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

class VcoreProfileForgotPassViewV2 extends StatelessWidget {
  const VcoreProfileForgotPassViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Quên mật khẩu',
      ),
      backgroundColor: AppColor.bgColor,
      body: const DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(
                    icon: Icon(Icons.support_agent),
                    text: 'Cổng hỗ trợ',
                  ),
                  Tab(
                    icon: Icon(Icons.mail_outline),
                    text: 'Gửi email',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  VcoreForgotPassSupportTabV2(),
                  VcoreForgotPassEmailTabV2(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}