import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/modules/inmapz/android/inmapz.dart';
import 'package:vnu_core/modules/inmapz/immap_view.dart';
import 'package:vnu_core/modules/inmapz/vcore_inzmap_controller.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

import '../map/views/vcore_map_view.dart';

class VcoreImmapView extends GetView<VcoreInzmapController> {
  const VcoreImmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreInzmapController(),
      tag: const Uuid().v4(),
      builder: (controller) => Scaffold(
        // appBar: Platform.isIOS
        //     ? NaviWidget(
        //         titleStr: 'Bản đồ số',
        //         rightActions: [
        //           IconButton(
        //               onPressed: () {
        //                 Get.to(
        //                   () => const VcoreMapView(),
        //                 );
        //               },
        //               icon: const Icon(Icons.map_rounded))
        //         ],
        //       )
        //     : null,
        body: Platform.isIOS
            ? const IMMapView()
            : const SafeArea(child: IMMapViewAndroid()),
      ),
    );
  }
}
