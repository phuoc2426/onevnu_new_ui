import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_breakpoints.dart';

enum VnuWindowClass { compact, medium, expanded }

class VnuResponsiveContext {
  const VnuResponsiveContext({
    required this.width,
    required this.height,
    required this.textScale,
    required this.orientation,
  });

  final double width;
  final double height;
  final double textScale;
  final Orientation orientation;

  factory VnuResponsiveContext.of(
    BuildContext context, {
    BoxConstraints? constraints,
  }) {
    final media = MediaQuery.of(context);
    final width = constraints != null && constraints.hasBoundedWidth
        ? constraints.maxWidth
        : media.size.width;
    final height = constraints != null && constraints.hasBoundedHeight
        ? constraints.maxHeight
        : media.size.height;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return VnuResponsiveContext(
      width: width,
      height: height,
      textScale: scale,
      orientation: media.orientation,
    );
  }

  double get effectiveWidth => VnuBreakpoints.effectiveWidth(width, textScale);

  VnuWindowClass get windowClass {
    if (effectiveWidth < VnuBreakpoints.compact) return VnuWindowClass.compact;
    if (effectiveWidth < VnuBreakpoints.medium) return VnuWindowClass.medium;
    return VnuWindowClass.expanded;
  }

  bool get isCompact => windowClass == VnuWindowClass.compact;
  bool get isMedium => windowClass == VnuWindowClass.medium;
  bool get isExpanded => windowClass == VnuWindowClass.expanded;
  bool get isLargeText => textScale >= 1.4;
  bool get isVeryLargeText => textScale >= 1.8;
  bool get isShortViewport => height < 560;

  bool shouldStack({
    int columns = 2,
    double minChildWidth = 240,
    double spacing = 12,
  }) {
    final required = (minChildWidth * columns) + (spacing * (columns - 1));
    return effectiveWidth < required;
  }
}
