import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One content rail for the REAL payment overview and detail views.
/// On phones it uses the full available width; wide Flutter Web/tablet
/// viewports remain a phone-like 460dp wide instead of stretching the PNG.
abstract final class TuitionResponsiveWidth {
  static const double maxContentWidth = 460.0;
  static const double listMargin = 4.0;
  static const double detailMargin = 9.0;

  static double content(double availableWidth) =>
      math.max(0.0, math.min(maxContentWidth, availableWidth));

  static double listPaper(double availableWidth) =>
      math.max(0.0, content(availableWidth) - 2 * listMargin);

  static double detailPaper(double availableWidth) =>
      math.max(0.0, content(availableWidth) - 2 * detailMargin);
}

/// Center without scaling text or artwork. Keep native logical-pixel sizes;
/// only restrict the parent width. This also works in a scrolling ListView.
class TuitionResponsiveFrame extends StatelessWidget {
  const TuitionResponsiveFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: TuitionResponsiveWidth.content(availableWidth),
          child: child,
        ),
      );
    },
  );
}
