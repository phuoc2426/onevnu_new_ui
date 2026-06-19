import 'package:flutter/material.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/views/forgot_password_v2/vcore_forgot_pass_email_tab_v2.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreProfileForgotPassViewV2 extends StatelessWidget {
  const VcoreProfileForgotPassViewV2({super.key});

  const VcoreProfileForgotPassViewV2.loginSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Quên mật khẩu',
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Gửi yêu cầu hỗ trợ lấy lại mật khẩu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            spaceHeight(16),
            const Expanded(
              child: VcoreForgotPassEmailTabV2(
                isEmbedded: true,
                prefillFromCache: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
