import 'package:flutter/material.dart';

/// Shared geometry for all OneVNU form controls.
///
/// P2V2 rule: a one-line field's height depends on accessibility text scale,
/// never on the length of the current value. This keeps adjacent inputs
/// aligned while still respecting large text settings.
class VnuFieldMetrics {
  VnuFieldMetrics._();

  static const double radius = 14;
  static const double baseMinHeight = 54;
  static const double compactBaseMinHeight = 48;
  static const double optionMinHeight = 50;

  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: 14,
  );

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  static double textScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1);
  }

  static double minHeightFor(
    BuildContext context, {
    bool compact = false,
  }) {
    final scale = textScale(context);
    final base = compact ? compactBaseMinHeight : baseMinHeight;

    if (scale >= 1.8) return base + 14;
    if (scale >= 1.4) return base + 8;
    return base;
  }

  static double toolbarHeightFor(BuildContext context) {
    final scale = textScale(context);
    if (scale >= 1.8) return 72;
    if (scale >= 1.4) return 66;
    return 60;
  }
}
