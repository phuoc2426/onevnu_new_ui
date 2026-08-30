import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/shapeshifter/models/shapeshifter_feature.dart';
import 'package:vnu_core/modules/shapeshifter/views/vcore_shapeshifter_webview.dart';

class ShapeshifterLauncher {
  ShapeshifterLauncher._internal();

  static final ShapeshifterLauncher _instance =
      ShapeshifterLauncher._internal();

  factory ShapeshifterLauncher() => _instance;

  bool _opening = false;

  Future<void> open(
    BuildContext context,
    ShapeshifterFeature feature,
  ) async {
    if (_opening) return;
    _opening = true;
    try {
      if (!context.mounted) return;
      await Get.to(
        () => VcoreShapeshifterWebView(feature: feature),
      );
    } finally {
      _opening = false;
    }
  }
}
