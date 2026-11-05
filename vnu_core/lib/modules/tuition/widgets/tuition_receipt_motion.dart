import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_physical_feed.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_responsive_width.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_printer_artwork.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_tail.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_particles.dart';

/// The animations are visual-only. No timer, gesture, or frame creates a
/// payment request. All positions are Flutter logical pixels (dp).
abstract final class TuitionReceiptMotionConfig {
  static const Duration waveDuration = Duration(milliseconds: 370);
  static const Duration waveStagger = Duration(milliseconds: 65);
  static const Duration detailRiseDuration = Duration(milliseconds: 380);

  // HTML V16 physical feed: old receipt -> printer -> stochastic feed ->
  // detach and lower -> dock. The paper exists fully BEFORE it is fed.
  static const Duration printIntroDuration = Duration(milliseconds: 280);
  // V22 tear/yank has a short hold before the longer eased docking motion.
  static const Duration printDetachDuration = Duration(milliseconds: 175);
  static const Duration printTearHoldDuration = Duration(milliseconds: 110);
  static const Duration printFinishDuration = Duration(milliseconds: 410);
  static const Duration printParticlesDuration = Duration(milliseconds: 700);
  static const double paperTailHeight = 126;
  static const double paperTailPeek = 52;
  static const double paperTailStub = 16;
  static const double tearDiagonalX = 12;
  static const double tearDiagonalY = 26;
  static const double tearNearScale = 1.075;
  static const double tearRotation = 0.038;
  static const Duration printCancelDuration = Duration(milliseconds: 165);
  static const Duration acceleratedPullDuration = Duration(milliseconds: 135);
  static const double oldReceiptExitFraction = 0.54;
  static const double printerArrivalFraction = 1.0;
  static const double printPlaybackSpeed = 1.25;
  static const double waitingFeedCap = .91;
  static const double printInkBlur = 0.0;
  static const double detailMargin = 9;
  static const double printerBleedPerSide = 20;
  static const String printerAsset = 'assets/tinktalk/printer_bill.png';
  static const String printerBundleKey =
      'packages/vnu_core/assets/tinktalk/printer_bill.png';
  // Printer should be a THIN head below AppBar, never a 170dp block.
  // Width is still screen + 40dp, alpha-cropped to the visible PNG.
  static const double printerHeightToWidth = 0.14;
  static const double printerMinHeight = 46;
  static const double printerMaxHeight = 64;
  static const double printerMouthYFraction = 0.88;
  static const double printedPaperScale = 0.76;
  static const double tappedPaperPull = 15;
  static const double printedPaperMaxFraction = 1.0;

  static double printerWidth(double screenWidth) =>
      screenWidth + 2 * printerBleedPerSide;

  static double printerHeight(double screenWidth) =>
      (printerWidth(screenWidth) * printerHeightToWidth)
          .clamp(printerMinHeight, printerMaxHeight).toDouble();

  /// Physical ticket remains content-driven and can be longer than the
  /// screen. Only the *animation representation* is clamped to what is
  /// visible. This avoids RenderFlex stripes with long mock/detail fields.
  static Rect visiblePreviewRect(Rect measured, Size viewport) {
    final w = viewport.width.isFinite ? viewport.width : 0.0;
    final h = viewport.height.isFinite ? viewport.height : 0.0;
    if (w < 1 || h < 1) return Rect.zero;
    final left = measured.left.clamp(0.0, w).toDouble();
    final width = measured.width.clamp(0.0, w - left).toDouble();
    final top = measured.top.clamp(0.0, math.max(0.0, h - 48.0)).toDouble();
    final height = measured.height.clamp(0.0, math.max(0.0, h - top - 8.0)).toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }
}

class TuitionTicketWaveEntrance extends StatefulWidget {
  const TuitionTicketWaveEntrance({super.key, required this.index,
    required this.generation, required this.child});
  final int index;
  final int generation;
  final Widget child;
  @override
  State<TuitionTicketWaveEntrance> createState() =>
      _TuitionTicketWaveEntranceState();
}

class _TuitionTicketWaveEntranceState extends State<TuitionTicketWaveEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
      vsync: this, duration: TuitionReceiptMotionConfig.waveDuration);
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() {
    _delay?.cancel();
    _slide.reset();
    _delay = Timer(
        TuitionReceiptMotionConfig.waveStagger *
            widget.index.clamp(0, 8).toInt(), () {
      if (mounted) _slide.forward();
    });
  }

  @override
  void didUpdateWidget(covariant TuitionTicketWaveEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.generation != oldWidget.generation ||
        widget.index != oldWidget.index) _play();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _slide,
    child: widget.child,
    builder: (context, child) {
      final progress = Curves.easeOutCubic.transform(_slide.value);
      final width = MediaQuery.sizeOf(context).width;
      final distance = math.min(104.0, width * 0.26);
      return Opacity(
        opacity: progress.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(distance * (1 - progress), 0), child: child),
      );
    },
  );
}

class TuitionDetailRiseEntrance extends StatefulWidget {
  const TuitionDetailRiseEntrance({super.key, required this.child});
  final Widget child;
  @override
  State<TuitionDetailRiseEntrance> createState() =>
      _TuitionDetailRiseEntranceState();
}

class _TuitionDetailRiseEntranceState extends State<TuitionDetailRiseEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this, duration: TuitionReceiptMotionConfig.detailRiseDuration)
    ..forward();

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _rise,
    child: widget.child,
    builder: (context, child) {
      final progress = Curves.easeOutCubic.transform(_rise.value);
      return Transform.translate(
        offset: Offset(0, 62.0 * (1 - progress)),
        child: Opacity(
            opacity: progress.clamp(0.0, 1.0).toDouble(), child: child),
      );
    },
  );
}


enum TuitionPrintOutcome { waitingForGateway, succeeded, failed }

/// A skeleton resembling the REAL QR ticket, including its original detail
/// mask. Nothing in here contains a real QR, student details, or a payment URL.
/// It is fully built before the paper starts feeding and stays the same size.
class TuitionPrintingTicketSkeleton extends StatelessWidget {
  const TuitionPrintingTicketSkeleton({super.key, required this.fullSize});
  final Size fullSize;

  @override
  Widget build(BuildContext context) {
    // A full-page PNG mask, but the mock ink is one bounded CustomPainter.
    // Never lay out a large QR and multiple fixed-height Rows inside a small
    // printing sheet: that used to throw RenderFlex overflow below the QR.
    // Reserve generous top/bottom room for the actual scalloped-mask insets.
    final inkHeight = math.max(1.0, fullSize.height - 100.0);
    return SizedBox(
      width: fullSize.width,
      height: fullSize.height,
      child: ClipRect(child: TuitionTicketPaper(
        kind: TuitionTicketKind.detail,
        margin: 0,
        minHeight: fullSize.height,
        child: SizedBox(
          width: double.infinity,
          height: inkHeight,
          child: const RepaintBoundary(
            child: CustomPaint(painter: _TuitionSkeletonInkPainter()),
          ),
        ),
      )),
    );
  }
}

/// Painter scales ALL ink as one composition. Grey placeholder QR and lines
/// are inside the mask-safe body; no text widget or hard-coded pixel stack
/// can overflow the bottom edge while the entire paper is moving.
class _TuitionSkeletonInkPainter extends CustomPainter {
  const _TuitionSkeletonInkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1 || size.height <= 1) return;
    const grey = Color(0xFFD9E1DC);
    const light = Color(0xFFE9EEEA);
    const stroke = Color(0xFFC7D2CB);
    final ink = Paint()..color = grey;
    final shade = Paint()..color = light;
    final outline = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    void bar(double x, double y, double width, double height,
        {bool pale = false}) {
      final r = Rect.fromLTWH(size.width * x, size.height * y,
          size.width * width, math.max(2.0, size.height * height));
      canvas.drawRRect(RRect.fromRectAndRadius(r,
          const Radius.circular(3)), pale ? shade : ink);
    }

    // The top two lines are placeholders for heading / amount.
    bar(.28, .055, .44, .022, pale: true);
    bar(.15, .13, .70, .033);

    // QR does NOT need real bank pixels during printing. Restrict its side
    // using both width and height, preserving the remaining details below.
    final qrSide = math.max(0.0, math.min(size.width * .62, size.height * .38));
    final qr = Rect.fromLTWH((size.width - qrSide) / 2,
        size.height * .23, qrSide, qrSide);
    canvas.drawRRect(RRect.fromRectAndRadius(qr,
        const Radius.circular(4)), shade);
    canvas.drawRRect(RRect.fromRectAndRadius(qr,
        const Radius.circular(4)), outline);

    final lowerBound = math.max(.63, .23 + qrSide / size.height + .04);
    bar(.30, lowerBound, .40, .014);
    bar(.18, lowerBound + .055, .64, .014, pale: true);

    // Decorative dashed divider and 3 rows from the bottom information zone.
    final dashY = size.height * .80;
    for (var x = size.width * .05; x < size.width * .95; x += 13) {
      canvas.drawLine(Offset(x, dashY),
          Offset(math.min(size.width * .95, x + 7), dashY), outline);
    }
    bar(.06, .84, .22, .018, pale: true);
    bar(.52, .84, .42, .018);
    bar(.06, .895, .18, .018, pale: true);
    bar(.60, .895, .34, .018);
    bar(.06, .95, .21, .017, pale: true);
    bar(.44, .95, .50, .017);
  }

  @override
  bool shouldRepaint(covariant _TuitionSkeletonInkPainter oldDelegate) => false;
}

/// A fully composed, low-cost sheet used only when resource warmup reached
/// its maximum time. It has no decoded PNG or QR; all artwork is paint-only.
class _TuitionWarmupFallbackSheet extends StatelessWidget {
  const _TuitionWarmupFallbackSheet({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: const RepaintBoundary(child: CustomPaint(
      painter: _TuitionWarmupFallbackPainter())),
  );
}

class _TuitionWarmupFallbackPainter extends CustomPainter {
  const _TuitionWarmupFallbackPainter();
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final r = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(r,
      const Radius.circular(11)), Paint()..color = const Color(0xFFFFFEFA));
    final grey = Paint()..color = const Color(0xFFE3EAE5);
    void bar(double x, double y, double w, double h) => canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * x,
        size.height * y, size.width * w, size.height * h),
        const Radius.circular(3)), grey);
    bar(.22, .11, .56, .025);
    bar(.16, .17, .68, .022);
    final qr = math.min(size.width * .55, size.height * .32);
    canvas.drawRect(Rect.fromLTWH((size.width - qr) / 2,
      size.height * .30, qr, qr), Paint()..color = const Color(0xFFE9EEEA));
    bar(.16, .76, .68, .015);
    bar(.20, .82, .60, .015);
    bar(.12, .88, .76, .015);
  }
  @override
  bool shouldRepaint(covariant _TuitionWarmupFallbackPainter old) => false;
}

class _TuitionWarmupFallbackPrinter extends StatelessWidget {
  const _TuitionWarmupFallbackPrinter();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: Color(0xFF39433E),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(9))),
    child: Align(alignment: Alignment.bottomCenter,
      child: SizedBox(height: 6,
        child: ColoredBox(color: Color(0xFF1F2823)))),
  );
}

/// Physical feed model from HTML V16, rendered natively in Flutter.
/// The COMPLETE mask is initially above the mouth. A fixed ClipRect below
/// the printer shows its lower (leading) edge move downwards. We never reveal
/// content using clip-path/animated height, or randomize Y per frame.
/// The only successful QR comes from the parent after CREATE/RECREATE returns.
class TuitionReceiptPrinterStage extends StatefulWidget {
  const TuitionReceiptPrinterStage({super.key,
    required this.attemptSerial,
    required this.outcome,
    required this.targetRect,
    required this.outgoingReceipt,
    required this.receipt,
    required this.title,
    required this.amount,
    required this.onFinished,
    this.feedSpeed = TuitionReceiptMotionConfig.printPlaybackSpeed,
    this.paperScale = TuitionReceiptMotionConfig.printedPaperScale,
    this.printingSkeleton,
    this.blurPrintingPaper = false,
    this.lightweightPreview = false,
  });

  final int attemptSerial;
  final TuitionPrintOutcome outcome;
  final Rect? Function() targetRect;
  final Widget outgoingReceipt;
  final Widget receipt;
  final String title;
  final String amount;
  final VoidCallback onFinished;
  /// Visual-only tuning parameters. They never affect payment/QR APIs.
  final double feedSpeed;
  final double paperScale;
  /// Optional, fixed-size visual used only WHILE printing. Lets the debug lab
  /// test the actual production motion with cheap hard-coded QR artwork.
  /// If null, the production ticket-mask skeleton is used unchanged.
  final Widget? printingSkeleton;
  /// Default preserves the current live effect. Debug mock shows clean gray
  /// placeholder lines/QR without Gaussian blur over the whole ticket.
  final bool blurPrintingPaper;
  /// A hard preparation timeout chooses this paint-only fallback for ONE
  /// attempt. It avoids starting alpha masks and large PNG renders mid-motion.
  final bool lightweightPreview;

  @override
  State<TuitionReceiptPrinterStage> createState() =>
      _TuitionReceiptPrinterStageState();
}

class _TuitionReceiptPrinterStageState extends State<TuitionReceiptPrinterStage>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this, duration: TuitionReceiptMotionConfig.printIntroDuration);
  late final AnimationController _detach = AnimationController(
    vsync: this, duration: TuitionReceiptMotionConfig.printDetachDuration);
  late final AnimationController _finish = AnimationController(
    vsync: this, duration: TuitionReceiptMotionConfig.printFinishDuration);
  late final AnimationController _tearHold = AnimationController(
    vsync: this, duration: TuitionReceiptMotionConfig.printTearHoldDuration);
  late final AnimationController _particles = AnimationController(
    vsync: this, duration: TuitionReceiptMotionConfig.printParticlesDuration);
  late final AnimationController _cancel = AnimationController(
    vsync: this, duration: TuitionReceiptMotionConfig.printCancelDuration);

  late TuitionPhysicalFeed _feed;
  late final Ticker _paperTicker;
  final ValueNotifier<double> _feedFrame = ValueNotifier<double>(0);
  Duration? _lastFrame;
  double _accumulator = 0;
  double _boostSeconds = 0;
  bool _resolving = false;
  bool _done = false;
  // Geometry must not jump while CREATE changes QR/content height.
  Rect? _initialTarget;

  @override
  void initState() {
    super.initState();
    _feed = TuitionPhysicalFeed(seed: widget.attemptSerial * 7103 + 17);
    _paperTicker = createTicker(_tickPaper);
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _respondToGateway();
    });
    _detach.addStatusListener((status) {
      if (status == AnimationStatus.completed) _tearHold.forward();
    });
    _tearHold.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish.forward();
    });
    _finish.addStatusListener((status) {
      if (status == AnimationStatus.completed) _doneOnce();
    });
    _cancel.addStatusListener((status) {
      if (status == AnimationStatus.completed) _doneOnce();
    });
    _intro.forward();
  }

  @override
  void didUpdateWidget(covariant TuitionReceiptPrinterStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attemptSerial != widget.attemptSerial) {
      _paperTicker.stop();
      _feed = TuitionPhysicalFeed(seed: widget.attemptSerial * 7103 + 17);
      _feedFrame.value = 0;
      _lastFrame = null;
      _accumulator = 0;
      _boostSeconds = 0;
      _resolving = false;
      _done = false;
      _initialTarget = null;
      _detach.reset();
      _tearHold.reset();
      _particles.reset();
      _finish.reset();
      _cancel.reset();
      _intro.forward(from: 0);
    } else if (oldWidget.outcome != widget.outcome) {
      _respondToGateway();
    }
  }

  void _respondToGateway() {
    if (!mounted || _done || !_intro.isCompleted || _resolving) return;
    if (widget.outcome == TuitionPrintOutcome.failed) {
      _resolving = true;
      _paperTicker.stop();
      _cancel.forward();
    } else if (widget.outcome == TuitionPrintOutcome.succeeded &&
        _feed.progress >= .999) {
      _startDetach();
    } else {
      _resumeFeed();
    }
  }

  void _resumeFeed() {
    if (_resolving || _paperTicker.isActive) return;
    _lastFrame = null;
    _paperTicker.start();
  }

  void _tickPaper(Duration elapsed) {
    if (!mounted || _resolving) return;
    if (_lastFrame == null) {
      _lastFrame = elapsed;
      return;
    }
    final dt = ((elapsed - _lastFrame!).inMicroseconds / 1000000.0)
        .clamp(0.0, .06).toDouble();
    _lastFrame = elapsed;
    _accumulator += dt;
    const step = 1 / 120.0;
    final cap = widget.outcome == TuitionPrintOutcome.waitingForGateway
        ? TuitionReceiptMotionConfig.waitingFeedCap : 1.0;
    for (var n = 0; n < 8 && _accumulator >= step; n++) {
      _feed.step(step,
        speed: widget.feedSpeed.clamp(0.5, 4.0).toDouble(),
        cap: cap,
        boosted: _boostSeconds > 0);
      _boostSeconds = math.max(0.0, _boostSeconds - step);
      _accumulator -= step;
    }
    _feedFrame.value = _feed.progress;
    if (_feed.progress >= cap - .001) {
      _paperTicker.stop();
      if (widget.outcome == TuitionPrintOutcome.succeeded) _startDetach();
    }
  }

  void _startDetach() {
    if (!mounted || _resolving) return;
    _resolving = true;
    _paperTicker.stop();
    _particles.forward(from: 0);
    _detach.forward();
  }

  void _speedUpPaper() {
    if (!mounted || _resolving || !_intro.isCompleted ||
        _feed.progress >= 1) return;
    _boostSeconds = 1.0; // A touch accelerates the FEED, never calls an API.
    if (!_paperTicker.isActive) _resumeFeed();
  }

  void _doneOnce() {
    if (!mounted || _done) return;
    _done = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _paperTicker.dispose();
    _feedFrame.dispose();
    _intro.dispose();
    _detach.dispose();
    _tearHold.dispose();
    _particles.dispose();
    _finish.dispose();
    _cancel.dispose();
    super.dispose();
  }

  Widget _scalePaper({required Widget page,
      required Size original, required Size size}) =>
    ClipRect(child: SizedBox(width: size.width, height: size.height,
      child: FittedBox(fit: BoxFit.fill, alignment: Alignment.topLeft,
        child: SizedBox(width: original.width, height: original.height,
          child: ClipRect(child: page))),
    ));

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ClipRect(
      child: LayoutBuilder(builder: (context, limits) {
        final vw = limits.maxWidth;
        final vh = limits.maxHeight;
        if (vw <= 0 || vh <= 0) return const SizedBox.shrink();

        final fallbackWidth = TuitionResponsiveWidth.detailPaper(vw);
        final fallbackTop = math.min(vh * .28,
            math.max(0.0, vh - 390.0));
        final fallbackHeight = math.max(0.0,
            math.min(510.0, vh - fallbackTop - 8.0));
        final measured = widget.targetRect() ?? Rect.fromLTWH(
          (vw - fallbackWidth) / 2, fallbackTop,
          fallbackWidth, fallbackHeight,
        );

        // The scrollable REAL ticket is not resized or truncated. The printer
        // only animates a viewport-sized representation of that ticket.
        // Freeze it before the request can change detail content/height.
        final visible = TuitionReceiptMotionConfig.visiblePreviewRect(
            measured, Size(vw, vh));
        final target = _initialTarget ??= visible;
        final latest = TuitionReceiptMotionConfig.visiblePreviewRect(
            widget.targetRect() ?? measured, Size(vw, vh));
        // If the source document exceeds the viewport, use a lightweight
        // skeleton in the animation, not a forcibly constrained multi-row
        // real invoice (the latter caused yellow/black RenderFlex stripes).
        final oversized = measured.height > visible.height + 0.5 ||
            latest.height > visible.height + 0.5 ||
            target.height < 280;
        final finalTarget = latest.isEmpty ? target : latest;
        final printerWidth = TuitionReceiptMotionConfig.printerWidth(vw);
        final printerHeight = TuitionReceiptMotionConfig.printerHeight(vw);
        final mouthY = printerHeight *
            TuitionReceiptMotionConfig.printerMouthYFraction;
        final scale = widget.paperScale.clamp(.55, .90).toDouble();
        final smallSize = Size(target.width * scale,
            target.height * scale);
        final paperX = (vw - smallSize.width) / 2;
        const peek = TuitionReceiptMotionConfig.paperTailPeek;
        const tailHeight = TuitionReceiptMotionConfig.paperTailHeight;
        const stub = TuitionReceiptMotionConfig.paperTailStub;

        // IMPORTANT: these subtree instances are built ONCE for each parent
        // update. The following animation tick only changes raster-layer
        // transforms. The expensive PNG masks/QR do not rebuild at 60/120Hz.
        final paperArt = widget.lightweightPreview
            ? _TuitionWarmupFallbackSheet(size: smallSize)
            : RepaintBoundary(child: _scalePaper(
                page: widget.printingSkeleton ??
                    TuitionPrintingTicketSkeleton(fullSize: target.size),
                original: target.size,
                size: smallSize,
              ));
        final outgoingArt = widget.lightweightPreview
            ? _TuitionWarmupFallbackSheet(size: target.size)
            : RepaintBoundary(child: oversized
                ? TuitionPrintingTicketSkeleton(fullSize: target.size)
                : widget.outgoingReceipt);
        final incomingArt = (oversized || widget.lightweightPreview)
            ? paperArt
            : RepaintBoundary(child: _scalePaper(
                page: widget.receipt,
                original: finalTarget.size,
                size: smallSize,
              ));
        final printerArt = widget.lightweightPreview
            ? const RepaintBoundary(child: _TuitionWarmupFallbackPrinter())
            : RepaintBoundary(child: TuitionPrinterArtwork(
                width: printerWidth,
                height: printerHeight,
                assetKey: TuitionReceiptMotionConfig.printerBundleKey,
              ));

        return AnimatedBuilder(
          animation: Listenable.merge([
            _intro, _detach, _tearHold, _particles,
            _finish, _cancel, _feedFrame,
          ]),
          builder: (context, _) {
            final intro = _intro.value;
            final oldExit = Curves.easeInCubic.transform(
                (intro / TuitionReceiptMotionConfig.oldReceiptExitFraction)
                    .clamp(0.0, 1.0).toDouble());
            final descend = Curves.easeOutCubic.transform(
                ((intro - TuitionReceiptMotionConfig.oldReceiptExitFraction) /
                    (1 - TuitionReceiptMotionConfig.oldReceiptExitFraction))
                    .clamp(0.0, 1.0).toDouble());
            final detach = Curves.easeOutQuint.transform(_detach.value);
            final dock = Curves.easeInOutCubic.transform(_finish.value);
            final cancel = Curves.easeOutCubic.transform(_cancel.value);
            final progress = _feedFrame.value;
            final attached = _intro.isCompleted && _detach.value == 0 &&
                _tearHold.value == 0 && _finish.value == 0;
            final tearing = !attached &&
                (_detach.value > 0 || _tearHold.value > 0 ||
                 _finish.value > 0);
            final hasPrinter = intro >=
                TuitionReceiptMotionConfig.oldReceiptExitFraction;

            // Full paper moves, no changing height or layout while feeding.
            final sheetTop = -smallSize.height +
                (smallSize.height + peek) * progress * (1 - cancel);
            final yankX = TuitionReceiptMotionConfig.tearDiagonalX * detach;
            final yankY = TuitionReceiptMotionConfig.tearDiagonalY * detach;
            final near = 1.0 +
                (TuitionReceiptMotionConfig.tearNearScale - 1.0) * detach;
            final dockingX = paperX + yankX +
                (finalTarget.left - paperX - yankX) * dock;
            final initialDockY = mouthY + peek + yankY;
            final dockingY = initialDockY +
                (finalTarget.top - initialDockY) * dock;
            final xScale = near +
                (finalTarget.width / math.max(1.0, smallSize.width) - near) * dock;
            final yScale = near +
                (finalTarget.height / math.max(1.0, smallSize.height) - near) * dock;
            final rotation = TuitionReceiptMotionConfig.tearRotation *
                detach * (1 - dock);
            final showOld = oldExit < 1 || cancel > 0;

            return Stack(clipBehavior: Clip.hardEdge, children: [
              if (showOld)
                Positioned(
                  left: target.left,
                  top: target.top,
                  width: target.width,
                  height: target.height,
                  child: IgnorePointer(child: Transform.translate(
                    offset: Offset(
                      -(vw + target.width) *
                          (cancel > 0 ? 1 - cancel : oldExit),
                      -6.0 * (1 - cancel) * oldExit,
                    ),
                    child: Transform.rotate(
                      angle: -0.055 * oldExit * (1 - cancel),
                      child: Opacity(
                        opacity: (cancel > 0 ? cancel : 1 - oldExit)
                            .clamp(0.0, 1.0).toDouble(),
                        child: ClipRect(child: outgoingArt),
                      ),
                    ),
                  )),
                ),

              // The paper is ONE permanent render subtree in every phase.
              // Only transform and paint clipping change. Do not reparent
              // the heavy PNG mask between feed and tear: that produced a
              // noticeable stutter at exactly the most visible transition.
              if (cancel < 1)
                Positioned(
                  key: const ValueKey('tuition_paper_aperture'),
                  left: paperX,
                  top: mouthY,
                  width: smallSize.width,
                  height: math.max(0.0, vh - mouthY),
                  child: ClipRect(child: Stack(children: [
                    if (attached)
                      Positioned(
                        left: 0, top: 0,
                        width: smallSize.width,
                        height: tailHeight,
                        child: Transform.translate(
                          offset: Offset(0, sheetTop - tailHeight),
                          child: const IgnorePointer(
                            child: TuitionReceiptTail()),
                        ),
                      ),
                    if (tearing && dock < 1)
                      Positioned(
                        left: 0, top: 0,
                        width: smallSize.width,
                        height: tailHeight,
                        child: Transform.translate(
                          offset: Offset(0, -tailHeight + peek -
                              (peek - stub) * detach - stub * dock),
                          child: const IgnorePointer(
                            child: TuitionReceiptTail(torn: true)),
                        ),
                      ),
                  ])),
                ),
              Positioned(
                key: const ValueKey('tuition_physical_paper'),
                left: 0, top: 0,
                width: smallSize.width,
                height: smallSize.height,
                child: Transform.translate(
                  offset: Offset(
                    tearing ? dockingX : paperX,
                    tearing ? dockingY : mouthY + sheetTop,
                  ),
                  child: Transform.rotate(
                    angle: rotation,
                    alignment: Alignment.topCenter,
                    child: Transform.scale(
                      scaleX: tearing ? xScale : 1.0,
                      scaleY: tearing ? yScale : 1.0,
                      alignment: Alignment.topLeft,
                      child: ClipRect(
                        clipper: _TuitionPaperFeedClipper(
                          clipFromTop: tearing ? 0.0 :
                              (attached ? math.max(0.0, -sheetTop) :
                                  smallSize.height),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: attached ? _speedUpPaper : null,
                          child: IgnorePointer(
                            ignoring: !attached,
                            child: Stack(fit: StackFit.expand, children: [
                              Opacity(
                                opacity: (1 - cancel) * (1 - dock),
                                child: paperArt,
                              ),
                              if (!oversized)
                                Opacity(
                                  opacity: dock.clamp(0.0, 1.0).toDouble(),
                                  child: incomingArt,
                                ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (hasPrinter && cancel < 1 && dock < 1)
                Positioned(
                  key: const ValueKey('tuition_printer_artwork'),
                  left: -TuitionReceiptMotionConfig.printerBleedPerSide,
                  top: 0,
                  width: printerWidth,
                  height: printerHeight,
                  child: IgnorePointer(child: Transform.translate(
                    offset: Offset(0,
                      -(1 - descend) * (printerHeight + 8) -
                      printerHeight * cancel - printerHeight * dock +
                      (_paperTicker.isActive ? _feed.recoil : 0),
                    ),
                    child: Opacity(
                      opacity: (1 - cancel - dock)
                          .clamp(0.0, 1.0).toDouble(),
                      child: printerArt,
                    ),
                  )),
                ),

              // Localized 5-cluster hand-drawn particle layer: 60dp high,
              // instead of an expensive full-viewport repaint each frame.
              if (_particles.value > 0 && _particles.value < 1 && cancel < 1)
                Positioned(
                  left: paperX - 12,
                  top: mouthY + peek - 18,
                  width: smallSize.width + 24,
                  height: 62,
                  child: IgnorePointer(child: RepaintBoundary(
                    child: CustomPaint(
                      painter: TuitionReceiptTearParticlePainter(
                        progress: _particles.value,
                        left: 12,
                        width: smallSize.width,
                        top: 18,
                        seed: widget.attemptSerial,
                      ),
                    ),
                  )),
                ),
            ]);
          },
        );
      }),
    ),
  );
}

/// Only the moving physical paper is clipped at the stationary print mouth.
/// At the start, its entire body is above the mouth; after feeding it is
/// completely visible. This is a paint clip, not a size/layout animation.
class _TuitionPaperFeedClipper extends CustomClipper<Rect> {
  const _TuitionPaperFeedClipper({required this.clipFromTop});
  final double clipFromTop;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    0,
    clipFromTop.clamp(0.0, size.height).toDouble(),
    size.width,
    size.height,
  );

  @override
  bool shouldReclip(covariant _TuitionPaperFeedClipper oldClipper) =>
      (clipFromTop - oldClipper.clipFromTop).abs() > 0.05;
}
