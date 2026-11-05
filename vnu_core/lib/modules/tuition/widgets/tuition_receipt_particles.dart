import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small hand-drawn strokes and specks on the five points where the receipt
/// separates from the roll. This restores the restrained V22 tear effect.
/// The motion is deterministic for an attempt and never allocates particles
/// or draws QR pixels in a build/frame callback.
class TuitionReceiptTearParticlePainter extends CustomPainter {
  const TuitionReceiptTearParticlePainter({
    required this.progress,
    required this.left,
    required this.width,
    required this.top,
    required this.seed,
  });

  final double progress;
  final double left;
  final double width;
  final double top;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || width <= 0) return;
    for (var cluster = 0; cluster < 5; cluster++) {
      final x0 = left + width * (.11 + cluster * .195);
      final y0 = top + ((cluster % 2) == 0 ? 7.0 : 9.0);
      final count = 3 + (cluster % 2);
      for (var n = 0; n < count; n++) {
        // No per-frame randomness. Distinct, reproducible impulses with
        // staggered delays, decreasing velocity and mild downward gravity.
        final unit = ((seed * 13 + cluster * 47 + n * 29) % 113) / 113.0;
        final delay = n * .037 + cluster * .009;
        final duration = .74 - n * .036 + unit * .05;
        final p = ((progress - delay) / duration)
            .clamp(0.0, 1.0).toDouble();
        if (p <= 0 || p >= 1) continue;
        final launch = 1.0 - math.pow(1.0 - p, 2.3).toDouble();
        final fall = math.pow(math.max(0.0, (p - .28) / .72), 2).toDouble();
        final dir = n.isOdd ? -1.0 : 1.0;
        final drift = (3.5 + 6.2 * unit) * dir * launch;
        final lift = -(6.0 + 6 * unit) * launch;
        final px = x0 + drift;
        final py = y0 + lift + (8.0 + 4 * unit) * fall;
        final opacity = (math.min(1.0, p / .12) *
            math.max(0.0, 1.0 - math.pow(p, 1.15).toDouble()) * .85)
            .clamp(0.0, 1.0).toDouble();
        final paint = Paint()
          ..color = const Color(0xFF48554C).withOpacity(opacity)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = n == 0 ? 1.65 : 2.05;
        if (n == 0) {
          canvas.drawCircle(Offset(px, py), 1.1, paint);
        } else {
          final angle = (n == 1 ? -2.2 : n == 2 ? -.55 : 2.5) +
              (unit - .5) * .4;
          final length = 5.5 + 3.0 * unit;
          canvas.drawLine(Offset(px, py), Offset(
            px + math.cos(angle) * length,
            py + math.sin(angle) * length,
          ), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TuitionReceiptTearParticlePainter old) =>
      progress != old.progress || left != old.left || width != old.width ||
      top != old.top || seed != old.seed;
}
