import 'package:flutter/material.dart';

import 'forgot_password_v2/vcore_forgot_pass_email_tab_v2.dart';
import 'forgot_password_v2/vcore_forgot_pass_support_tab_v2.dart';

class VcoreProfileForgotPassViewV2 extends StatelessWidget {
  const VcoreProfileForgotPassViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lấy lại mật khẩu'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.confirmation_number_outlined),
                text: 'Cổng hỗ trợ',
              ),
              Tab(
                icon: Icon(Icons.email_outlined),
                text: 'Gửi email',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            VcoreForgotPassSupportTabV2(),
            VcoreForgotPassEmailTabV2(),
          ],
        ),
      ),
    );
  }
}