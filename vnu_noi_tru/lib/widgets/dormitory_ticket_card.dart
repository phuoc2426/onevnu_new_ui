import 'package:flutter/material.dart';

/// Horizontal receipt/ticket surface used by dormitory invoices.
///
/// The shape follows a real ticket: side notches separate the body/action bar,
/// while a second pair of notches plus a vertical dashed perforation create the
/// QR/status stub on the right. It is implemented with Flutter primitives so
/// the project owns the rendering and does not depend on a ticket package.
class DormitoryTicketCard extends StatelessWidget {
  const DormitoryTicketCard({
    super.key,
    required this.accentColor,
    required this.child,
    required this.footer,
    this.footerHeight = 42,
    this.stubFraction = 0.76,
    this.notchRadius = 8,
    this.stubNotchRadius = 6,
    this.radius = 16,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.onBodyTap,
  });

  final Color accentColor;
  final Widget child;
  final Widget footer;
  final double footerHeight;
  final double stubFraction;
  final double notchRadius;
  final double stubNotchRadius;
  final double radius;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onBodyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: _DormitoryTicketBorderPainter(
          accentColor: accentColor,
          footerHeight: footerHeight,
          stubFraction: stubFraction,
          notchRadius: notchRadius,
          stubNotchRadius: stubNotchRadius,
          radius: radius,
        ),
        child: ClipPath(
          clipper: _DormitoryTicketClipper(
            footerHeight: footerHeight,
            stubFraction: stubFraction,
            notchRadius: notchRadius,
            stubNotchRadius: stubNotchRadius,
            radius: radius,
          ),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  onTap: onBodyTap,
                  child: child,
                ),
                SizedBox(
                  height: footerHeight,
                  width: double.infinity,
                  child: ColoredBox(
                    color: accentColor,
                    child: footer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Path _ticketPath(
  Size size, {
  required double footerHeight,
  required double stubFraction,
  required double notchRadius,
  required double stubNotchRadius,
  required double radius,
}) {
  final double footerY = (size.height - footerHeight)
      .clamp(radius + notchRadius, size.height - radius)
      .toDouble();
  final double stubX = (size.width * stubFraction)
      .clamp(radius + stubNotchRadius, size.width - radius - stubNotchRadius)
      .toDouble();

  final Path outer = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ),
    );

  final Path notches = Path()
    // Horizontal tear line between invoice body and action strip.
    ..addOval(
      Rect.fromCircle(center: Offset(0, footerY), radius: notchRadius),
    )
    ..addOval(
      Rect.fromCircle(
        center: Offset(size.width, footerY),
        radius: notchRadius,
      ),
    )
    // Vertical ticket stub for QR/status, matching the demo ticket language.
    ..addOval(
      Rect.fromCircle(center: Offset(stubX, 0), radius: stubNotchRadius),
    )
    ..addOval(
      Rect.fromCircle(
        center: Offset(stubX, footerY),
        radius: stubNotchRadius,
      ),
    );

  return Path.combine(PathOperation.difference, outer, notches);
}

class _DormitoryTicketClipper extends CustomClipper<Path> {
  const _DormitoryTicketClipper({
    required this.footerHeight,
    required this.stubFraction,
    required this.notchRadius,
    required this.stubNotchRadius,
    required this.radius,
  });

  final double footerHeight;
  final double stubFraction;
  final double notchRadius;
  final double stubNotchRadius;
  final double radius;

  @override
  Path getClip(Size size) {
    return _ticketPath(
      size,
      footerHeight: footerHeight,
      stubFraction: stubFraction,
      notchRadius: notchRadius,
      stubNotchRadius: stubNotchRadius,
      radius: radius,
    );
  }

  @override
  bool shouldReclip(covariant _DormitoryTicketClipper oldClipper) {
    return oldClipper.footerHeight != footerHeight ||
        oldClipper.stubFraction != stubFraction ||
        oldClipper.notchRadius != notchRadius ||
        oldClipper.stubNotchRadius != stubNotchRadius ||
        oldClipper.radius != radius;
  }
}

class _DormitoryTicketBorderPainter extends CustomPainter {
  const _DormitoryTicketBorderPainter({
    required this.accentColor,
    required this.footerHeight,
    required this.stubFraction,
    required this.notchRadius,
    required this.stubNotchRadius,
    required this.radius,
  });

  final Color accentColor;
  final double footerHeight;
  final double stubFraction;
  final double notchRadius;
  final double stubNotchRadius;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _ticketPath(
      size,
      footerHeight: footerHeight,
      stubFraction: stubFraction,
      notchRadius: notchRadius,
      stubNotchRadius: stubNotchRadius,
      radius: radius,
    );

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..color = accentColor.withOpacity(0.34);
    canvas.drawPath(path, borderPaint);

    final double footerY = size.height - footerHeight;
    final double stubX = size.width * stubFraction;
    final Paint dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withOpacity(0.28);

    _drawDashedHorizontal(
      canvas,
      dashPaint,
      y: footerY,
      startX: notchRadius + 7,
      endX: size.width - notchRadius - 7,
    );

    _drawDashedVertical(
      canvas,
      dashPaint,
      x: stubX,
      startY: stubNotchRadius + 7,
      endY: footerY - stubNotchRadius - 7,
    );
  }

  void _drawDashedHorizontal(
    Canvas canvas,
    Paint paint, {
    required double y,
    required double startX,
    required double endX,
  }) {
    const double dash = 4;
    const double gap = 4;
    double x = startX;
    while (x < endX) {
      final double end = (x + dash).clamp(x, endX).toDouble();
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  void _drawDashedVertical(
    Canvas canvas,
    Paint paint, {
    required double x,
    required double startY,
    required double endY,
  }) {
    const double dash = 4;
    const double gap = 4;
    double y = startY;
    while (y < endY) {
      final double end = (y + dash).clamp(y, endY).toDouble();
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DormitoryTicketBorderPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.footerHeight != footerHeight ||
        oldDelegate.stubFraction != stubFraction ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.stubNotchRadius != stubNotchRadius ||
        oldDelegate.radius != radius;
  }
}
