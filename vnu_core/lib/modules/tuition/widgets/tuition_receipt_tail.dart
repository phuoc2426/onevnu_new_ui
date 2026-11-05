import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The extra roll of paper from the HTML V22 animation. It is physically
/// joined to the receipt during feeding and retracts after the tear; it is
/// not an artificial growth/reveal of the main ticket.
class TuitionReceiptTail extends StatelessWidget {
  const TuitionReceiptTail({super.key, this.torn = false});
  final bool torn;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _TuitionReceiptTailPainter(torn: torn),
      child: const SizedBox.expand()),
  );
}

class _TuitionReceiptTailPainter extends CustomPainter {
  const _TuitionReceiptTailPainter({required this.torn});
  final bool torn;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final paper = Paint()..color = const Color(0xFFFFFEFA);
    if (!torn) {
      canvas.drawRect(bounds, paper);
    } else {
      final path = Path()..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height - 3);
      for (var x = size.width; x >= 0; x -= 2.2) {
        final notch = 2.2 * math.sin(x * math.pi / 13.0);
        path.lineTo(x, size.height - 3 + notch);
      }
      path..lineTo(0, 0)..close();
      canvas.drawPath(path, paper);
    }
    final border = Paint()
      ..color = const Color(0xFFD6E1D8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(.5, 0), Offset(.5, size.height), border);
    canvas.drawLine(Offset(size.width - .5, 0),
      Offset(size.width - .5, size.height), border);
    if (!torn) {
      canvas.drawLine(Offset(0, size.height - 1),
        Offset(size.width, size.height - 1), border);
    }
  }

  @override
  bool shouldRepaint(covariant _TuitionReceiptTailPainter old) =>
      torn != old.torn;
}
