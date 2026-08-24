import 'dart:math' as math;

/// Width classes are based on the space actually available to a widget, not
/// on device names. This keeps split-screen/tablet layouts predictable.
abstract final class VnuBreakpoints {
  static const double compact = 600;
  static const double medium = 900;

  static double effectiveWidth(double width, double textScale) {
    return width / math.max(1.0, math.min(textScale, 2.0));
  }
}
