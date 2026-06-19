import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/paht_v2/controllers/vcore_paht_controller_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_comunitation_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_create_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_person_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_search_view_v2.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcorePahtViewV2 extends GetView<VcorePahtControllerV2> {
  const VcorePahtViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcorePahtControllerV2>(
      init: VcorePahtControllerV2(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return VcoreModuleScaffold(
          title: 'Phản ánh hiện trường',
          actions: [
            IconButton(
              onPressed: () {
                Get.to(() => VcorePahtSearchViewV2());
              },
              icon: svgAsset('assets/images/ic_search.svg', color: Colors.black87, width: 28),
            ),
          ],
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: const [
                _PahtV2HeaderTabs(),
                Expanded(
                  child: TabBarView(
                    children: [
                      VcorePahtComunitationViewV2(),
                      VcorePahtPersonViewV2(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.colorMain,
            onPressed: () async {
              await Get.to(() => const VcorePahtCreateViewV2());
            },
            child: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _PahtV2HeaderTabs extends StatelessWidget {
  const _PahtV2HeaderTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF3F6F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppTheme.colorMain,
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xff0B1B44),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Cộng đồng'),
          Tab(text: 'Của tôi'),
        ],
      ),
    );
  }
}
