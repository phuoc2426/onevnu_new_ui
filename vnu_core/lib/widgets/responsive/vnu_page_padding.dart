import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_context.dart';

abstract final class VnuPagePadding {
  static EdgeInsets resolve(BuildContext context) {
    final r = VnuResponsiveContext.of(context);
    switch (r.windowClass) {
      case VnuWindowClass.compact:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case VnuWindowClass.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      case VnuWindowClass.expanded:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
  }
}
