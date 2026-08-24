import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/widgets/field/vnu_field_metrics.dart';

class VnuSelectTheme {
  VnuSelectTheme._();

  static const double fieldMinHeight = VnuFieldMetrics.baseMinHeight;
  static const double optionMinHeight = VnuFieldMetrics.optionMinHeight;
  static const double radius = VnuFieldMetrics.radius;
  static const double optionRadius = 12;
  static const double sheetRadius = 24;
  static const double maxSheetHeightFactor = 0.78;

  static const EdgeInsets fieldPadding = VnuFieldMetrics.contentPadding;

  static const EdgeInsets sheetBodyPadding = EdgeInsets.fromLTRB(14, 10, 14, 20);

  static const Color border = AppColors.border;
  static const Color selectedBorder = AppColors.greenAccent;
  static const Color selectedBackground = Color(0xFFEAF7EF);
  static const Color disabledBackground = Color(0xFFF5F6F7);
  static const Color optionHover = Color(0xFFF5F7F6);
  static const Color error = AppColors.error;

  static double resolvedFieldMinHeight(
    BuildContext context, {
    bool compact = false,
  }) {
    return VnuFieldMetrics.minHeightFor(context, compact: compact);
  }
}
