import 'package:flutter/material.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_mine_view.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class PahtForumMinePage extends StatelessWidget {
  const PahtForumMinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const VcoreModuleScaffold(
      title: 'Phản ánh của tôi',
      body: PahtForumMineView(),
    );
  }
}
