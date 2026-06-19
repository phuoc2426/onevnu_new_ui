import 'package:flutter/material.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_password_manager_view_v2.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreProfileChangePassViewV2 extends StatelessWidget {
  const VcoreProfileChangePassViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return const VcoreModuleScaffold(
      title: 'Quản lý mật khẩu',
      body: VcoreProfilePasswordManagerViewV2(initialTab: 0, isEmbedded: true),
    );
  }
}
