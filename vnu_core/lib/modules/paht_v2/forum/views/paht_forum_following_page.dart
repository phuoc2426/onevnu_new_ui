import 'package:flutter/material.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_following_view.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class PahtForumFollowingPage extends StatelessWidget {
  const PahtForumFollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const VcoreModuleScaffold(
      title: 'Đang theo dõi',
      body: PahtForumFollowingView(),
    );
  }
}
