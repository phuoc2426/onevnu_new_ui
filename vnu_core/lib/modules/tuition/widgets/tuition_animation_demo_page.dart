import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';

/// Pure UI laboratory. Uses the SAME TuitionReceiptPrinterStage as real
/// payments, but every receipt, QR and gateway reply is simulated locally.
/// In particular this screen never invokes the tuition gateway or SSO APIs.
class TuitionAnimationDemoPage extends StatefulWidget {
  const TuitionAnimationDemoPage({super.key});

  @override
  State<TuitionAnimationDemoPage> createState() =>
      _TuitionAnimationDemoPageState();
}

class _TuitionAnimationDemoPageState extends State<TuitionAnimationDemoPage> {
  Timer? _fakeResponse;
  int _qrVersion = 1;
  int _attempt = 0;
  bool _printing = false;
  double _paperSpeed = 1.25;
  int _mockDelayMs = 800;
  String _notice = 'Mã QR hiện tại được giữ nguyên cho đến khi in thành công.';
  TuitionPrintOutcome _outcome = TuitionPrintOutcome.waitingForGateway;

  @override
  void dispose() {
    _fakeResponse?.cancel();
    super.dispose();
  }

  void _runPrinter({required bool succeed}) {
    if (_printing) return;
    _fakeResponse?.cancel();
    final request = ++_attempt;
    setState(() {
      _printing = true;
      _outcome = TuitionPrintOutcome.waitingForGateway;
      _notice = 'Đang in giấy mẫu · không gửi yêu cầu thanh toán.';
    });
    _fakeResponse = Timer(Duration(milliseconds: _mockDelayMs), () {
      if (!mounted || !_printing || request != _attempt) return;
      setState(() => _outcome = succeed
          ? TuitionPrintOutcome.succeeded
          : TuitionPrintOutcome.failed);
    });
  }

  void _onPrintFinished() {
    if (!mounted || !_printing) return;
    _fakeResponse?.cancel();
    setState(() {
      if (_outcome == TuitionPrintOutcome.succeeded) {
        _qrVersion += 1;
        _notice = 'Thành công: chuyển sang QR mô phỏng #$_qrVersion.';
      } else {
        _notice = 'Thất bại: giữ nguyên QR mô phỏng #$_qrVersion.';
      }
      _printing = false;
      _outcome = TuitionPrintOutcome.waitingForGateway;
    });
  }

  /// There are exactly TWO areas: this bounded preview, and the controls
  /// below it. An animation can never push the controls off the screen.
  Widget _preview() => LayoutBuilder(builder: (context, bounds) {
    final width = bounds.maxWidth;
    final height = bounds.maxHeight;
    // KEEP THE RECEIPT ASPECT RATIO: when vertical space is limited,
    // shrink its width instead of squashing the QR or pushing the card below.
    const ticketAspect = 405.0 / 350.0;
    final maximumWidth = math.min(392.0, math.max(1.0, width - 22.0));
    // Reserve the printer slot at the top, but guarantee bottom clearance.
    final top = math.min(math.max(96.0, height * .205),
        math.max(0.0, height - 110.0));
    final availableHeight = math.max(1.0, height - top - 13.0);
    final ticketWidth = math.min(maximumWidth,
        availableHeight / ticketAspect);
    final ticketHeight = ticketWidth * ticketAspect;
    final ticketX = (width - ticketWidth) / 2;
    final target = Rect.fromLTWH(ticketX, top, ticketWidth, ticketHeight);

    return Stack(clipBehavior: Clip.hardEdge, children: [
      const Positioned.fill(child: ColoredBox(color: Color(0xFFF8F6F1))),
      Positioned(left: 18, right: 18, top: 14,
        child: IgnorePointer(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TẠO MÃ THANH TOÁN · DEMO',
                style: TextStyle(color: Color(0xFF81968C),
                  fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('7.150.000 đ', style: TextStyle(
                color: const Color(0xFF064A3C), fontSize: width < 350 ? 26 : 30,
                fontWeight: FontWeight.w800)),
            Text('QR mẫu #${_qrVersion.toString().padLeft(3, '0')}',
                key: const ValueKey('tuition_demo_current_qr'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF81968C))),
          ],
        )),
      ),
      Positioned.fromRect(rect: target,
        child: IgnorePointer(child: Opacity(
          opacity: _printing ? 0 : 1,
          child: _FixedReceiptCard(
            key: const ValueKey('tuition_demo_static_receipt'),
            qrVersion: _qrVersion, isPrinting: false),
        )),
      ),
      if (_printing)
        TuitionReceiptPrinterStage(
          key: ValueKey<int>(_attempt),
          attemptSerial: _attempt,
          outcome: _outcome,
          // A stable rectangle in THIS Stack's own coordinate system.
          // No GlobalKey measuring, no late post-frame size correction.
          targetRect: () => target,
          title: 'Học phí',
          amount: '7.150.000 đ',
          outgoingReceipt: _FixedReceiptCard(
              qrVersion: _qrVersion, isPrinting: false),
          printingSkeleton: const _FixedReceiptCard(
              qrVersion: 0, isPrinting: true),
          receipt: _FixedReceiptCard(
              qrVersion: _qrVersion + 1, isPrinting: false),
          feedSpeed: _paperSpeed,
          paperScale: .76,
          onFinished: _onPrintFinished,
        ),
    ]);
  });

  Widget _controls() => Material(
    color: Colors.white,
    elevation: 5,
    child: SafeArea(top: false, child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: FilledButton.icon(
            key: const ValueKey('tuition_demo_success'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
              backgroundColor: const Color(0xFF0B7858)),
            onPressed: _printing ? null : () => _runPrinter(succeed: true),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const FittedBox(fit: BoxFit.scaleDown,
                child: Text('In QR thành công')),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            key: const ValueKey('tuition_demo_failure'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact),
            onPressed: _printing ? null : () => _runPrinter(succeed: false),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const FittedBox(fit: BoxFit.scaleDown,
                child: Text('Thử API thất bại')),
          )),
        ]),
        Row(children: [
          const Text('Tốc độ in', style: TextStyle(fontSize: 12)),
          Expanded(child: Slider(
            key: const ValueKey('tuition_demo_speed'),
            min: .75, max: 2.5, divisions: 35,
            value: _paperSpeed,
            onChanged: (value) => setState(() => _paperSpeed = value),
          )),
          SizedBox(width: 47,
            child: Text('${_paperSpeed.toStringAsFixed(2)}×',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700))),
        ]),
        Row(children: [
          Expanded(child: Text(_notice,
            key: const ValueKey('tuition_demo_notice'),
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF536D60)))),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(child: DropdownButton<int>(
            key: const ValueKey('tuition_demo_latency'),
            value: _mockDelayMs,
            isDense: true,
            onChanged: _printing ? null : (v) =>
                setState(() => _mockDelayMs = v ?? 800),
            items: const [
              DropdownMenuItem(value: 250, child: Text('0,25s',
                  style: TextStyle(fontSize: 11))),
              DropdownMenuItem(value: 800, child: Text('0,8s',
                  style: TextStyle(fontSize: 11))),
              DropdownMenuItem(value: 2400, child: Text('2,4s',
                  style: TextStyle(fontSize: 11))),
            ],
          )),
        ]),
      ]),
    )),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F6F1),
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('Demo in mã QR',
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      actions: const [Padding(
        padding: EdgeInsets.only(right: 12),
        child: Center(child: Text('KHÔNG GỌI API',
          style: TextStyle(color: Color(0xFF7B9284), fontSize: 10))),
      )],
    ),
    body: LayoutBuilder(builder: (context, viewport) {
      // A separate, fixed-size control bar prevents the previous Stack overlap.
      final preferredControls = math.min(174.0,
          math.max(128.0, viewport.maxHeight * .28));
      final controlHeight = math.min(preferredControls,
          math.max(0.0, viewport.maxHeight * .45));
      return Column(children: [
        Expanded(child: _preview()),
        SizedBox(height: controlHeight, child: _controls()),
      ]);
    }),
  );
}

/// A fully pre-rendered, fixed-size QR ticket. No live API, no layout-growing
/// text Column, no skeleton shimmer, and no QR that could authorize payment.
class _FixedReceiptCard extends StatelessWidget {
  const _FixedReceiptCard({super.key,
    required this.qrVersion, required this.isPrinting});
  final int qrVersion;
  final bool isPrinting;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _FixedReceiptPainter(qrVersion, isPrinting),
      child: const SizedBox.expand(),
    ),
  );
}

class _FixedReceiptPainter extends CustomPainter {
  const _FixedReceiptPainter(this.id, this.printing);
  final int id;
  final bool printing;

  void _bar(Canvas canvas, Paint brush,
      double x, double y, double w, double h) {
    if (w <= 0 || h <= 0) return;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h), Radius.circular(h / 2)), brush);
  }

  void _word(Canvas canvas, String label, Offset offset,
      {required double fontSize, Color color = const Color(0xFF174E3F),
      FontWeight weight = FontWeight.w700}) {
    final painter = TextPainter(
      text: TextSpan(text: label,
        style: TextStyle(color: color, fontSize: fontSize,
          fontWeight: weight, height: 1.1)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 285);
    painter.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;

    // Draw the whole paper at its final size; scale once for small previews.
    canvas.save();
    canvas.scale(w / 350.0, h / 405.0);
    final shape = Path()..addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 350, 405), const Radius.circular(14)));
    final cutouts = Path();
    for (var y = 19.0; y < 402; y += 20.0) {
      cutouts.addOval(Rect.fromCircle(center: Offset(0, y), radius: 4.1));
      cutouts.addOval(Rect.fromCircle(center: Offset(350, y), radius: 4.1));
    }
    final outline = Path.combine(PathOperation.difference, shape, cutouts);
    canvas.drawShadow(outline, const Color(0xFF304C3B), 8, false);
    canvas.drawPath(outline, Paint()..color = const Color(0xFFFFFFFF));
    canvas.save();
    canvas.clipPath(outline);

    if (printing) {
      // Skeleton: a gray QR rectangle and short WHITE strokes, deliberately
      // not text or a real QR. This is already present before paper feeds.
      final base = Paint()..color = const Color(0xFFE6EBE8);
      final white = Paint()..color = Colors.white;
      _bar(canvas, base, 54, 39, 135, 13);
      _bar(canvas, white, 58, 42, 95, 5);
      _bar(canvas, base, 38, 69, 274, 23);
      _bar(canvas, white, 46, 77, 225, 7);
      canvas.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(90, 110, 170, 170), const Radius.circular(4)),
        Paint()..color = const Color(0xFFCDD5CF));
      _bar(canvas, white, 118, 183, 118, 6);
      _bar(canvas, base, 70, 297, 210, 10);
      _bar(canvas, white, 98, 299, 153, 5);
      _bar(canvas, base, 43, 345, 117, 11);
      _bar(canvas, white, 47, 347, 88, 6);
      _bar(canvas, base, 193, 345, 114, 11);
      _bar(canvas, white, 198, 347, 91, 6);
    } else {
      _word(canvas, 'MÃ THANH TOÁN', const Offset(94, 38),
        fontSize: 13, color: const Color(0xFF7B8B83));
      _word(canvas, 'Quét mã để thanh toán', const Offset(61, 69),
        fontSize: 20);
      const qrRect = Rect.fromLTWH(97, 117, 156, 156);
      canvas.drawRect(qrRect, Paint()..color = Colors.white);
      canvas.drawRect(qrRect, Paint()
        ..color = const Color(0xFF0F7156)
        ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      final rand = math.Random(id * 3989 + 51);
      final ink = Paint()..color = const Color(0xFF16392C);
      const n = 25;
      const d = 5.45;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          final finder = (r < 8 && c < 8) ||
            (r < 8 && c > 16) || (r > 16 && c < 8);
          if (finder || rand.nextBool() == false) continue;
          canvas.drawRect(Rect.fromLTWH(
            107 + c * d, 127 + r * d, d * .91, d * .91), ink);
        }
      }
      for (final xy in <Offset>[
        const Offset(107, 127),
        const Offset(107 + 18 * d, 127),
        const Offset(107, 127 + 18 * d),
      ]) {
        canvas.drawRect(Rect.fromLTWH(xy.dx, xy.dy, d * 7, d * 7), ink);
        canvas.drawRect(Rect.fromLTWH(xy.dx + d, xy.dy + d, d * 5, d * 5),
          Paint()..color = Colors.white);
        canvas.drawRect(Rect.fromLTWH(xy.dx + d * 2, xy.dy + d * 2,
          d * 3, d * 3), ink);
      }
      _word(canvas, 'DEMO #${id.toString().padLeft(3, '0')} · KHÔNG QUÉT',
        const Offset(66, 293), fontSize: 12,
        color: const Color(0xFF6A8B79));
      _bar(canvas, Paint()..color = const Color(0xFFE5ECE7),
        38, 322, 274, 2);
      _word(canvas, 'Chi tiết', const Offset(35, 335), fontSize: 18);
      _bar(canvas, Paint()..color = const Color(0xFFD8E1DA),
          37, 374, 104, 8);
      _bar(canvas, Paint()..color = const Color(0xFFD8E1DA),
          185, 374, 126, 8);
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FixedReceiptPainter old) =>
      old.id != id || old.printing != printing;
}
