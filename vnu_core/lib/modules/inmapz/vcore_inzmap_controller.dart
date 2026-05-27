import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/inmapz/immap_view.dart';

class VcoreInzmapController extends GetxController
    implements IMMapViewControllerDelegate {
  IMMapViewController? mapViewController;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if (Platform.isIOS) {
      iniControllerMap();
    }
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }

  iniControllerMap() {
    if (mapViewController != null) {
      return;
    }

    mapViewController = IMMapViewController();
    mapViewController?.setDelegate(this);
  }

  @override
  void closeMapView() {
    Get.back();
  }
}
