import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/modules/tuition/data/tuition_charge_category.dart';

/// Ticket silhouette is a PNG alpha mask, NOT a background containing text.
/// The entire painting layer stretches with the rendered card. All interactive
/// elements live in a separate safe content subtree; the mask cannot clip text.
/// If the user has not yet copied list.png/detail.png, a vector paper silhouette
/// is painted instead, keeping the view usable without fictional bundled art.
enum TuitionTicketKind { list, detail }

/// Run once in Debug from the tuition screen. Reports *bundled* assets,
/// not files on the developer's PC. No secret, token or student data logged.
Future<void> debugAuditTuitionArtworkBundle() async {
  if (!kDebugMode) return;
  const revision = 'TICKET_SAFE_LAYOUT_V3_20261019';
  const keys = <String>[
    'packages/vnu_core/assets/tinktalk/list1.png',
    'packages/vnu_core/assets/tinktalk/list.png',
    'packages/vnu_core/assets/tinktalk/detail1.png',
    'packages/vnu_core/assets/tinktalk/detail.png',
    'packages/vnu_core/assets/tinktalk/background_qr.png',
    'packages/vnu_core/assets/tinktalk/printer_bill.png',
  ];
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final available = manifest.listAssets().toSet();
    debugPrint('[ONEVNU_TUITION] ARTWORK_BUILD | $revision');
    for (final key in keys) {
      debugPrint('[ONEVNU_TUITION] ARTWORK_BUNDLE | '
        '${available.contains(key) ? 'FOUND' : 'MISSING'} | $key');
    }
  } catch (error) {
    debugPrint('[ONEVNU_TUITION] ARTWORK_BUNDLE | MANIFEST_FAILED | $error');
  }
}

/// Geometry is derived once from the ACTUAL alpha of list1/detail1.png.
/// The transparent whitespace around the silhouette is trimmed before paint.
/// `fraction` stores the deepest scallop on each edge, relative to the
/// trimmed PNG bounds (not the whole PNG canvas).
@immutable
class TuitionTicketMaskMetrics {
  const TuitionTicketMaskMetrics({
    required this.sourceRect,
    required this.cutFraction,
  });

  final Rect sourceRect;
  final EdgeInsets cutFraction;

  /// Safe inset = max(minimum UI spacing, furthest alpha indentation + gap).
  /// The gap is in Flutter LOGICAL pixels (dp), normally 8 dp.
  EdgeInsets contentInsets(Size paintedSize, {
    double gap = 8,
    EdgeInsets minimum = EdgeInsets.zero,
  }) => EdgeInsets.fromLTRB(
    math.max(minimum.left, paintedSize.width * cutFraction.left + gap),
    math.max(minimum.top, paintedSize.height * cutFraction.top + gap),
    math.max(minimum.right, paintedSize.width * cutFraction.right + gap),
    math.max(minimum.bottom, paintedSize.height * cutFraction.bottom + gap),
  );

  static Future<TuitionTicketMaskMetrics> fromImage(ui.Image image) async {
    final w = image.width;
    final h = image.height;
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) {
      return TuitionTicketMaskMetrics(
        sourceRect: Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        cutFraction: EdgeInsets.zero,
      );
    }
    // Bounded sampling keeps large PNGs responsive on modest phones.
    final step = math.max(1, (math.max(w, h) / 900).floor());
    int alpha(int x, int y) => rgba.getUint8((y * w + x) * 4 + 3);
    const solid = 180; // Ignore antialiased fringe and transparent shadows.
    var minX = w;
    var minY = h;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < h; y += step) {
      // Do not monopolise Flutter Web's UI event loop while inspecting a
      // high-resolution paper alpha mask. Allow a loading frame between
      // batches. This is precomputation, never performed in paint().
      if (y > 0 && (y ~/ step) % 70 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      for (var x = 0; x < w; x += step) {
        if (alpha(x, y) >= solid) {
          minX = math.min(minX, x);
          minY = math.min(minY, y);
          maxX = math.max(maxX, x);
          maxY = math.max(maxY, y);
        }
      }
    }
    if (maxX < minX || maxY < minY) {
      return TuitionTicketMaskMetrics(
        sourceRect: Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        cutFraction: EdgeInsets.zero,
      );
    }
    // Add one sample of bleed to avoid cutting off antialiased edges.
    final left = math.max(0, minX - step);
    final top = math.max(0, minY - step);
    final right = math.min(w - 1, maxX + step);
    final bottom = math.min(h - 1, maxY + step);
    final bw = math.max(1, right - left + 1);
    final bh = math.max(1, bottom - top + 1);
    var leftCut = 0;
    var rightCut = 0;
    var topCut = 0;
    var bottomCut = 0;
    // Skip extreme corner pixels: text never begins at the very corners.
    // Every other sampled scallop is included, including the middle notches.
    final yStart = top + (bh * 0.045).round();
    final yEnd = bottom - (bh * 0.045).round();
    final xStart = left + (bw * 0.13).round();
    final xEnd = right - (bw * 0.13).round();
    final yStep = math.max(step, (bh / 100).floor());
    final xStep = math.max(step, (bw / 100).floor());
    for (var y = yStart; y <= yEnd; y += yStep) {
      var x = left;
      while (x <= right && alpha(x, y) < solid) { x += step; }
      if (x <= right) leftCut = math.max(leftCut, x - left);
      x = right;
      while (x >= left && alpha(x, y) < solid) { x -= step; }
      if (x >= left) rightCut = math.max(rightCut, right - x);
    }
    for (var x = xStart; x <= xEnd; x += xStep) {
      var y = top;
      while (y <= bottom && alpha(x, y) < solid) { y += step; }
      if (y <= bottom) topCut = math.max(topCut, y - top);
      y = bottom;
      while (y >= top && alpha(x, y) < solid) { y -= step; }
      if (y >= top) bottomCut = math.max(bottomCut, bottom - y);
    }
    return TuitionTicketMaskMetrics(
      sourceRect: Rect.fromLTRB(left.toDouble(), top.toDouble(),
        (right + 1).toDouble(), (bottom + 1).toDouble()),
      cutFraction: EdgeInsets.fromLTRB(
        leftCut / bw, topCut / bh, rightCut / bw, bottomCut / bh),
    );
  }
}

class _TuitionMaskData {
  const _TuitionMaskData(this.image, this.metrics);
  final ui.Image image;
  final TuitionTicketMaskMetrics metrics;
}

abstract final class TuitionTicketDefaults {
  static const double sideMargin = 12;
  static const double listSafeX = 14;
  static const double listSafeY = 11;
  static const double detailSafeX = 16;
  static const double detailSafeY = 12;
  static const double stubWidth = 39;
  // Ticket A/B (list): B overlaps A, with a wavy, perforated left edge.
  // The whole paper is scaled to the original transparent PNG silhouette.
  // The white-over-colour seam is anchored to that *same* rendered width.
  static double listABSeamForWidth(double width) =>
      (width * 0.155).clamp(49.0, 62.0).toDouble();
  // Near-flat wave: seam moves at most 0.3 logical pixels either side.
  static const double listABWaveAmplitude = 0.3;
  static const double listABWavePeriod = 15.5;
  static const double listABFooterHeight = 40;
  static const double borderBleed = 12;
  static const Color paper = Color(0xFFFFFEFA);
  static const Color mint = Color(0xFFBDEBDC);
  static const Color sand = Color(0xFFFFE1A5);

  // Four intentionally distinct pastel category colours, never random:
  // FIRST_TIME mint, RETAKE sand, IMPROVEMENT lavender, OUT_OF_PROGRAM sky.
  static const Color lavender = Color(0xFFE2D8FF);
  static const Color sky = Color(0xFFCDE8FF);

  /// Without a trusted category code: mint / sand by CURRENT displayed index.
  /// This matches the original `index.isEven` design, including when filtered.
  static Color tintForCategory(TuitionChargeCategory? category, int index) =>
      switch (category) {
        TuitionChargeCategory.firstTime => mint,
        TuitionChargeCategory.retake => sand,
        TuitionChargeCategory.improvement => lavender,
        TuitionChargeCategory.outOfProgram => sky,
        null => index.isEven ? mint : sand,
      };

  /// Contrast-safe number on the colored A strip (not payment status color).
  static Color indexInkForTint(Color tint) {
    if (tint == mint) return const Color(0xFF0B5141);
    if (tint == sand) return const Color(0xFF94601B);
    if (tint == lavender) return const Color(0xFF5C3B8B);
    if (tint == sky) return const Color(0xFF205E85);
    return const Color(0xFF0B5141);
  }
}

class TuitionTicketPaper extends StatefulWidget {
  const TuitionTicketPaper({super.key, required this.kind, required this.child,
    this.tint, this.margin = TuitionTicketDefaults.sideMargin,
    this.minHeight, this.onTap, this.showListStitches = false});

  /// Shares the exact same decoded PNG/mask metrics Future as every ticket.
  /// Preparing does not construct any ticket widgets or payment requests.
  static Future<void> prewarmMask(TuitionTicketKind kind) async {
    await _TuitionMaskLoader.get(kind);
  }

  final TuitionTicketKind kind;
  final Widget child;
  final Color? tint;
  final double margin;
  final double? minHeight;
  final VoidCallback? onTap;
  final bool showListStitches;

  @override
  State<TuitionTicketPaper> createState() => _TuitionTicketPaperState();
}

class _TuitionTicketPaperState extends State<TuitionTicketPaper> {
  final GlobalKey _paperKey = GlobalKey();
  double? _actualHeight;

  void _measureAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = _paperKey.currentContext?.size;
      if (size == null) return;
      if (_actualHeight == null || (size.height - _actualHeight!).abs() > 0.75) {
        setState(() => _actualHeight = size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isList = widget.kind == TuitionTicketKind.list;
    // The real PNG is cached and measured exactly once per type.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.margin),
      child: FutureBuilder<_TuitionMaskData?>(
        future: _TuitionMaskLoader.get(widget.kind),
        builder: (context, snapshot) => LayoutBuilder(
          builder: (context, limits) {
            // Two-pass feedback is necessary: detail ticket height follows
            // wrapped text, and its top/bottom PNG cuts scale with that height.
            _measureAfterLayout();
            final imageSize = Size(limits.maxWidth,
              _actualHeight ?? widget.minHeight ?? (isList ? 148 : 415));
            final safe = snapshot.data?.metrics.contentInsets(imageSize,
              gap: 8,
              minimum: isList
                ? const EdgeInsets.fromLTRB(15, 12, 15, 12)
                : const EdgeInsets.fromLTRB(17, 24, 17, 18)) ??
              (isList ? const EdgeInsets.fromLTRB(15, 12, 15, 12)
                : const EdgeInsets.fromLTRB(17, 24, 17, 18));
            final body = Stack(key: _paperKey, clipBehavior: Clip.none, children: [
              // Keep the expensive PNG-alpha mask + blurred drop shadow in
              // its own raster layer. QR countdown, text and receipt movement
              // never need to repaint this unchanging background.
              Positioned.fill(child: IgnorePointer(child: RepaintBoundary(
                child: _TuitionPaperArtwork(kind: widget.kind,
                    tint: widget.tint, data: snapshot.data)))),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.minHeight ??
                  (isList ? 148 : 415)),
                child: Padding(padding: safe, child: widget.child),
              ),
              if (isList && widget.showListStitches)
                Positioned.fill(child: IgnorePointer(
                  child: RepaintBoundary(
                    child: TuitionTicketStitchOverlays(kind: widget.kind)))),
            ]);
            return widget.onTap == null ? body : Material(
              color: Colors.transparent,
              child: InkWell(onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent, child: body),
            );
          },
        ),
      ),
    );
  }
}

/// Independent border row (sibling of safe content, not nested within it).
/// Consequently the stroke may extend farther than text without leaking text
/// outside the ticket-safe inset. It scales to any parent ticket width.
class TuitionTicketDashedDivider extends StatelessWidget {
  const TuitionTicketDashedDivider({super.key,
    this.sideInset = TuitionTicketDefaults.borderBleed,
    this.color = const Color(0xFFB5C6B8), this.dash = 5, this.gap = 5});

  final double sideInset;
  final Color color;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: sideInset),
    child: SizedBox(height: 9,
      child: CustomPaint(painter: _DashPainter(color, dash, gap),
        child: const SizedBox.expand())),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color, this.dash, this.gap);
  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()..color = color..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0.0, size.width).toDouble(), y), pen);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) =>
      color != oldDelegate.color || dash != oldDelegate.dash || gap != oldDelegate.gap;
}

abstract final class _TuitionMaskLoader {
  static final Map<TuitionTicketKind, Future<_TuitionMaskData?>> _inFlight = {};

  static Future<_TuitionMaskData?> get(TuitionTicketKind kind) =>
      _inFlight.putIfAbsent(kind, () async {
        final candidates = kind == TuitionTicketKind.list
            ? const <String>['list1.png', 'list.png']
            : const <String>['detail1.png', 'detail.png'];
        for (final file in candidates) {
          try {
            final data = await rootBundle.load(
              'packages/vnu_core/assets/tinktalk/$file');
            final bytes = data.buffer.asUint8List(
              data.offsetInBytes, data.lengthInBytes);
            final codec = await ui.instantiateImageCodec(bytes);
            try {
              final image = (await codec.getNextFrame()).image;
              final metrics = await TuitionTicketMaskMetrics.fromImage(image);
              if (kDebugMode) {
                debugPrint('[ONEVNU_TUITION] MASK | $file | '
                  '${image.width}x${image.height} | '
                  'crop=${metrics.sourceRect} | '
                  'cut=${metrics.cutFraction} | safeGap=8dp');
              }
              return _TuitionMaskData(image, metrics);
            } finally {
              codec.dispose();
            }
          } catch (error) {
            if (kDebugMode) {
              debugPrint('[ONEVNU_TUITION] MASK_MISSING | $file | $error');
            }
          }
        }
        if (kDebugMode) {
          debugPrint('[ONEVNU_TUITION] MASK_FALLBACK | '
            '${candidates.join(', ')}');
        }
        return null;
      });
}

class _TuitionPaperArtwork extends StatelessWidget {
  const _TuitionPaperArtwork({required this.kind, required this.tint,
    required this.data});
  final TuitionTicketKind kind;
  final Color? tint;
  final _TuitionMaskData? data;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TicketPaperPainter(data: data, kind: kind, tint: tint),
    size: Size.infinite,
  );
}

class _TicketPaperPainter extends CustomPainter {
  const _TicketPaperPainter({required this.data, required this.kind, required this.tint});
  final _TuitionMaskData? data;
  final TuitionTicketKind kind;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final isList = kind == TuitionTicketKind.list;
    final depth = isList ? 3.0 : 4.0;
    final paperColor = TuitionTicketDefaults.paper;
    final stub = tint;
    final maskImage = data?.image;
    if (maskImage == null) {
      final path = _fallbackShape(size, isList);
      canvas.drawShadow(path, const Color(0x3A1E4231), isList ? 7 : 12, false);
      canvas.drawPath(path.shift(Offset(0, depth)),
        Paint()..color = const Color(0xFFD8E0D8));
      canvas.drawPath(path, Paint()..color = paperColor);
      if (stub != null) {
        canvas.save();
        canvas.clipPath(path);
        canvas.drawRect(Rect.fromLTWH(0, 0,
          TuitionTicketDefaults.listSafeX + TuitionTicketDefaults.stubWidth,
          size.height), Paint()..color = stub);
        canvas.restore();
      }
      return;
    }
    final src = data!.metrics.sourceRect;
    final shadow = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: isList ? 8 : 11,
        sigmaY: isList ? 8 : 11);
    canvas.saveLayer(rect.inflate(28), shadow);
    canvas.drawImageRect(maskImage, src,
      rect.shift(Offset(0, isList ? 6 : 11)),
      Paint()..filterQuality = FilterQuality.medium
        ..colorFilter = const ColorFilter.mode(
          Color(0x48152F22), BlendMode.srcIn));
    canvas.restore();
    canvas.drawImageRect(maskImage, src, rect.shift(Offset(0, depth)),
      Paint()..filterQuality = FilterQuality.medium
        ..colorFilter = const ColorFilter.mode(
          Color(0xFFD8E0D8), BlendMode.srcIn));
    // Keep BOTH the image alpha silhouette AND its original RGB shading.
    // The old dstIn-only renderer discarded all PNG texture/artwork and made
    // the ticket look like a plain vector rectangle even when a PNG loaded.
    // BlendMode.modulate multiplies the source RGB with the paper/tint and
    // multiplies alpha by the actual source alpha. A white PNG still works
    // as a transparent mask; a textured PNG keeps its paper detail.
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Paint()..color = paperColor);
    if (stub != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0,
        TuitionTicketDefaults.listSafeX + TuitionTicketDefaults.stubWidth,
        size.height), Paint()..color = stub);
    }
    canvas.drawImageRect(maskImage, src, rect,
      Paint()..filterQuality = FilterQuality.high
        ..blendMode = BlendMode.modulate);
    // Crucial: the entire painted paper must obey PNG alpha, not merely its RGB.
    canvas.drawImageRect(maskImage, src, rect,
      Paint()..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.dstIn);
    canvas.restore();
  }

  Path _fallbackShape(Size size, bool isList) {
    final w = size.width;
    final h = size.height;
    final outer = Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h), const Radius.circular(15)));
    final bites = Path();
    final step = isList ? 14.0 : 22.0;
    final radius = isList ? 3.2 : 5.5;
    for (double y = step; y < h - 6; y += step) {
      bites.addOval(Rect.fromCircle(center: Offset(0, y), radius: radius));
      bites.addOval(Rect.fromCircle(center: Offset(w, y), radius: radius));
    }
    return Path.combine(PathOperation.difference, outer, bites);
  }

  @override
  bool shouldRepaint(_TicketPaperPainter oldDelegate) =>
      data != oldDelegate.data || kind != oldDelegate.kind || tint != oldDelegate.tint;
}

/// Legacy single-layer ticket perforation strokes live outside the content
/// padding.  Each is its OWN overlaid CustomPaint layer.  We mask the paint
/// using list.png alpha, allowing the dashed stroke to bleed farther than the
/// text inset without drawing outside the real paper silhouette.
class TuitionTicketStitchOverlays extends StatelessWidget {
  const TuitionTicketStitchOverlays({super.key, required this.kind});
  final TuitionTicketKind kind;

  @override
  Widget build(BuildContext context) => FutureBuilder<_TuitionMaskData?>(
    future: _TuitionMaskLoader.get(kind),
    builder: (context, snapshot) => Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _TicketStitchPainter(
        mask: snapshot.data, kind: kind, vertical: true))),
      Positioned.fill(child: CustomPaint(painter: _TicketStitchPainter(
        mask: snapshot.data, kind: kind, vertical: false))),
    ]),
  );
}

class _TicketStitchPainter extends CustomPainter {
  const _TicketStitchPainter({required this.mask, required this.kind,
    required this.vertical});
  final _TuitionMaskData? mask;
  final TuitionTicketKind kind;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final pen = Paint()..color = const Color(0xFFB1C8BB)
      ..strokeWidth = 1..strokeCap = StrokeCap.round;
    canvas.saveLayer(bounds, Paint());
    if (vertical) {
      // Starts on the stub/white-paper seam, NOT at the text margin.
      final x = TuitionTicketDefaults.listSafeX +
          TuitionTicketDefaults.stubWidth + 3.0;
      for (double y = 6; y < size.height - 5; y += 8) {
        canvas.drawLine(Offset(x, y),
          Offset(x, (y + 4).clamp(0.0, size.height).toDouble()), pen);
      }
    } else {
      // 4px side margins instead of text padding -> long dashed border.
      final y = size.height - 41;
      for (double x = 4; x < size.width - 4; x += 9) {
        canvas.drawLine(Offset(x, y),
          Offset((x + 5).clamp(0.0, size.width - 4).toDouble(), y), pen);
      }
    }
    final maskImage = mask;
    if (maskImage != null) {
      canvas.drawImageRect(maskImage.image,
        maskImage.metrics.sourceRect, bounds,
        Paint()..filterQuality = FilterQuality.medium
          ..blendMode = BlendMode.dstIn);
    } else {
      // Fallback should not extend beyond rounded paper edges, either.
      canvas.drawRRect(RRect.fromRectAndRadius(bounds,
          const Radius.circular(13)),
        Paint()..color = Colors.white..blendMode = BlendMode.dstIn);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TicketStitchPainter old) =>
      mask != old.mask || kind != old.kind || vertical != old.vertical;
}

// ---------------------------------------------------------------------------
// True two-layer LIST ticket: A (colored backing) + B (white paper on top).
// The left edge of B is physically a wave, NOT a painted straight divider.
// The wave perforation is a mask overlay; the SHORT horizontal dotted border
// belongs exclusively to the deadline widget inside B.
// ---------------------------------------------------------------------------

/// The minimum ticket length is a design baseline, NOT a maximum height.
/// The actual height is the intrinsic height of A1, B and A2 plus the
/// mask-safe insets. The extra 30dp makes the V19 default less cramped.
class TuitionListTicketAB extends StatefulWidget {
  const TuitionListTicketAB({super.key, required this.indexLabel,
    required this.tint, required this.mainContent, required this.deadline,
    required this.onTap, this.leadingIcon,
    this.height = 189, this.margin = 4});

  final String indexLabel;
  final Color tint;
  final Widget? leadingIcon;
  final Widget mainContent;
  final Widget deadline;
  final VoidCallback onTap;
  final double height;
  final double margin;

  @override
  State<TuitionListTicketAB> createState() => _TuitionListTicketABState();
}

class _TuitionListTicketABState extends State<TuitionListTicketAB> {
  final GlobalKey _ticketKey = GlobalKey(debugLabel: 'tuition_list_measure');
  double? _renderedHeight;

  void _measureAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final h = _ticketKey.currentContext?.size?.height;
      if (h != null && h.isFinite && h > 0 &&
          (_renderedHeight == null || (h - _renderedHeight!).abs() > 0.75)) {
        setState(() => _renderedHeight = h);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final baseHeight = widget.height +
        math.max(0.0, textScale - 1) * 100;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.margin),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: widget.onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: LayoutBuilder(builder: (context, outer) =>
            FutureBuilder<_TuitionMaskData?>(
              future: _TuitionMaskLoader.get(TuitionTicketKind.list),
              builder: (_, snapshot) {
                _measureAfterLayout();
                final data = snapshot.data;
                final seam = TuitionTicketDefaults.listABSeamForWidth(
                  outer.maxWidth);
                // The mask's cut-in fraction changes with rendered height.
                // Re-measure when long labels or font scaling increase it.
                var safeHeight = math.max(baseHeight, _renderedHeight ?? 0);
                for (var pass = 0; pass < 4; pass++) {
                  final insets = data?.metrics.contentInsets(
                    Size(outer.maxWidth, safeHeight), gap: 8,
                    minimum: const EdgeInsets.fromLTRB(0, 13, 15, 13)) ??
                    const EdgeInsets.fromLTRB(0, 13, 15, 13);
                  safeHeight = math.max(safeHeight, baseHeight +
                    math.max(0.0, insets.top - 13) +
                    math.max(0.0, insets.bottom - 13));
                }
                final safe = data?.metrics.contentInsets(
                  Size(outer.maxWidth, safeHeight), gap: 8,
                  minimum: const EdgeInsets.fromLTRB(0, 13, 15, 13)) ??
                  const EdgeInsets.fromLTRB(0, 13, 15, 13);
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: safeHeight),
                  child: IntrinsicHeight(child: Stack(
                    key: _ticketKey,
                    children: [
                      Positioned.fill(child: IgnorePointer(child: CustomPaint(
                        painter: _TuitionListABPaperPainter(
                          data: data, tint: widget.tint)))),
                      Row(crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TuitionTicketSectionA(indexLabel: widget.indexLabel,
                            tint: widget.tint, seamWidth: seam),
                          Expanded(child: TuitionTicketSectionB(
                            leadingIcon: widget.leadingIcon,
                            mainContent: widget.mainContent,
                            deadline: widget.deadline,
                            availableWidth: outer.maxWidth - seam,
                            safeInsets: safe, onTap: widget.onTap)),
                        ]),
                      Positioned.fill(child: IgnorePointer(child: CustomPaint(
                        painter: _TuitionABWaveStitchPainter(data: data)))),
                    ],
                  )),
                );
              },
            )),
        ),
      ),
    );
  }
}

class TuitionTicketSectionA extends StatelessWidget {
  const TuitionTicketSectionA({super.key, required this.indexLabel,
    required this.tint, required this.seamWidth});
  final String indexLabel;
  final Color tint;
  final double seamWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: seamWidth,
    child: Center(child: Text(indexLabel,
      style: TextStyle(fontFamily: TextStyles.fontName,
        fontSize: 16, fontWeight: FontWeight.w800,
        color: TuitionTicketDefaults.indexInkForTint(tint)))),
  );
}

/// The white section B uses one mask-aware safe container containing:
///   row: [icon] [A1: title, period, amount, status + countdown] [B: arrow]
///   bottom: [A2: short dashed deadline box]
/// The arrow is a sibling of A1, NEVER a child of A2. The dashed line is
/// restricted to A2, and its hitbox does not cover the arrow.
class TuitionTicketSectionB extends StatelessWidget {
  const TuitionTicketSectionB({super.key, required this.mainContent,
    required this.deadline, required this.onTap, this.leadingIcon,
    this.safeInsets = const EdgeInsets.fromLTRB(0, 13, 15, 13),
    this.availableWidth = 300});

  final Widget? leadingIcon;
  final Widget mainContent;
  final Widget deadline;
  final VoidCallback onTap;
  final EdgeInsets safeInsets;
  final double availableWidth;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(13, safeInsets.top,
      safeInsets.right, safeInsets.bottom),
    child: Builder(builder: (context) {
      const arrowWidth = 41.0;
      const arrowHeight = 57.0;
      // LayoutBuilder has no intrinsic height. Use the B width supplied by
      // the parent so that a long A1 can enlarge the actual ticket height.
      final contentWidth = math.max(0.0,
        availableWidth - 13.0 - safeInsets.right);
      final deadlineWidth = math.max(0.0,
        math.min(170.0, contentWidth - arrowWidth - 7));
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (leadingIcon != null) ...[
              Padding(padding: const EdgeInsets.only(top: 1),
                child: SizedBox(width: 21, height: 24, child: Center(
                  child: leadingIcon))),
              const SizedBox(width: 6),
            ],
            Expanded(child: Align(
              alignment: Alignment.topLeft,
              child: mainContent)),
            const SizedBox(width: 2),
            // B: isolated arrow button, slightly taller than a normal icon.
            SizedBox(width: arrowWidth, height: arrowHeight,
              child: InkWell(onTap: onTap,
                key: const ValueKey<String>('tuition_ticket_arrow_B'),
                borderRadius: BorderRadius.circular(24),
                child: Center(child: DecoratedBox(
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    color: Color(0xFF07543F)),
                  child: const SizedBox(width: 31, height: 31,
                    child: Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 23)),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // A2: the DATE is a separate div BELOW A1 and B.
        SizedBox(width: deadlineWidth,
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const TuitionTicketDashedDivider(sideInset: 0,
                color: Color(0xFFAFBFB4), dash: 4.8, gap: 3.8),
              const SizedBox(height: 5),
              deadline,
            ])),
      ]);
    }),
  );
}

// This path is the SAME white-sheet edge used by the painted dashed seam.
// Both go through the original PNG's alpha clip at the rendered card size.
double _tuitionABWaveX(Size size, double y) =>
    TuitionTicketDefaults.listABSeamForWidth(size.width) +
    TuitionTicketDefaults.listABWaveAmplitude *
      math.sin(2 * math.pi * y / TuitionTicketDefaults.listABWavePeriod);

Path _tuitionABWhiteWavePath(Size size) {
  final seam = TuitionTicketDefaults.listABSeamForWidth(size.width);
  final p = Path()
    ..moveTo(size.width, 0)
    ..lineTo(seam, 0);
  for (double y = 0; y < size.height; y += 1.2) {
    p.lineTo(_tuitionABWaveX(size, y), y);
  }
  p..lineTo(seam, size.height)
   ..lineTo(size.width, size.height)
   ..close();
  return p;
}

Path _tuitionOuterFallback(Size size) {
  final whole = Path()..addRRect(RRect.fromRectAndRadius(
    Offset.zero & size, const Radius.circular(16)));
  final cuts = Path();
  for (double y = 11; y < size.height - 3; y += 16) {
    cuts.addOval(Rect.fromCircle(center: Offset(0, y), radius: 3.2));
    cuts.addOval(Rect.fromCircle(center: Offset(size.width, y), radius: 3.2));
  }
  return Path.combine(PathOperation.difference, whole, cuts);
}

void _tuitionClipToMask(Canvas canvas, Size size, _TuitionMaskData? data) {
  if (data != null) {
    canvas.drawImageRect(data.image,
      data.metrics.sourceRect,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.dstIn);
  } else {
    canvas.drawPath(_tuitionOuterFallback(size),
      Paint()..color = Colors.white..blendMode = BlendMode.dstIn);
  }
}

class _TuitionListABPaperPainter extends CustomPainter {
  const _TuitionListABPaperPainter({required this.data, required this.tint});
  final _TuitionMaskData? data;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    if (data == null) {
      canvas.drawShadow(_tuitionOuterFallback(size),
        const Color(0x441C3B2E), 8, false);
    } else {
      final shadow = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7);
      canvas.saveLayer(bounds.inflate(15), shadow);
      canvas.drawImageRect(data!.image,
        data!.metrics.sourceRect,
        bounds.shift(const Offset(0, 5)),
        Paint()..colorFilter = const ColorFilter.mode(
          Color(0x48182B23), BlendMode.srcIn));
      canvas.restore();
    }
    canvas.saveLayer(bounds, Paint());
    // A is underneath B. Preserve the actual user PNG silhouette AND its
    // embedded raster details; do not discard RGB like the former dstIn mask.
    canvas.drawRect(bounds, Paint()..color = tint);
    canvas.drawPath(_tuitionABWhiteWavePath(size),
      Paint()..color = TuitionTicketDefaults.paper);
    if (data != null) {
      final source = data!.metrics.sourceRect;
      // Modulate alone DOES NOT clip previously-painted opaque paper outside
      // the PNG. First retain original shading; then apply PNG alpha to the
      // ENTIRE combined A+B layer, including the white portion.
      canvas.drawImageRect(data!.image, source, bounds,
        Paint()..filterQuality = FilterQuality.high
          ..blendMode = BlendMode.modulate);
      canvas.drawImageRect(data!.image, source, bounds,
        Paint()..filterQuality = FilterQuality.medium
          ..blendMode = BlendMode.dstIn);
    } else {
      _tuitionClipToMask(canvas, size, null);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TuitionListABPaperPainter old) =>
      old.tint != tint || old.data != data;
}

abstract class _TuitionABMaskedStitchPainter extends CustomPainter {
  const _TuitionABMaskedStitchPainter({required this.data});
  final _TuitionMaskData? data;

  void paintDashedPath(Canvas canvas, Path path, Paint pen,
      {double dashLength = 3.4, double gapLength = 3.3}) {
    for (final metric in path.computeMetrics()) {
      double start = 0;
      while (start < metric.length) {
        canvas.drawPath(metric.extractPath(start,
          math.min(start + dashLength, metric.length)), pen);
        start += dashLength + gapLength;
      }
    }
  }

  void clipToBAndMask(Canvas canvas, Size size) {
    canvas.clipPath(_tuitionABWhiteWavePath(size));
    // Visual clip of the paper silhouette, including real scallop notches.
    final maskImage = data;
    if (maskImage == null) {
      canvas.clipPath(_tuitionOuterFallback(size));
    }
  }

  void finishMaskedStroke(Canvas canvas, Size size) {
    _tuitionClipToMask(canvas, size, data);
  }
}

/// Vertical *wave* perforation at the actual B-left contour.
class _TuitionABWaveStitchPainter extends _TuitionABMaskedStitchPainter {
  const _TuitionABWaveStitchPainter({required super.data});
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()..color = const Color(0xFFAFC8BB)
      ..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final path = Path();
    for (double y = 4; y < size.height - 4; y += 1.2) {
      final x = _tuitionABWaveX(size, y);
      if (y <= 4) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    paintDashedPath(canvas, path, pen, dashLength: 2.6, gapLength: 2.5);
    finishMaskedStroke(canvas, size);
    canvas.restore();
  }
  @override
  bool shouldRepaint(_TuitionABWaveStitchPainter old) => old.data != data;
}

// The horizontal dotted divider is deliberately part of the deadline
// widget in TuitionTicketSectionB, not a card-wide painter.

/// Optional QR panel background from the user's original tinktalk assets.
/// The four short green corner strokes surround the OUTER WHITE FRAME, not
/// the QR code itself. They remain separate from both artwork and QR data.
/// Inside the QR ticket this is only the WHITE scanner frame.
/// The user-supplied background_qr.png belongs to the entire DETAIL PAGE,
/// not behind the QR image where it reduces scan contrast.
class TuitionQrBackdrop extends StatelessWidget {
  const TuitionQrBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      // No pale green rounded frame, no light-green border.
      // The bank/provider QR remains an unmodified white, scannable image.
      Padding(
        padding: const EdgeInsets.all(9),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: child,
        ),
      ),
      Positioned.fill(child: IgnorePointer(
        child: CustomPaint(painter: _TuitionQrOuterCorners()))),
    ],
  );
}

/// The full-page detailed QR artwork; never render it a second time inside
/// the white QR scanner area.  The image is supplied by the user's project.
class TuitionDetailPageBackground extends StatelessWidget {
  const TuitionDetailPageBackground({super.key});

  static const String asset = 'assets/tinktalk/background_qr.png';
  static bool _reportedLoaded = false;
  static bool _reportedMissing = false;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Image.asset(asset,
      package: 'vnu_core',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (kDebugMode && frame != null && !_reportedLoaded) {
          _reportedLoaded = true;
          debugPrint('[ONEVNU_TUITION] QR_BACKGROUND | LOADED | '
            'packages/vnu_core/$asset');
        }
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode && !_reportedMissing) {
          _reportedMissing = true;
          debugPrint('[ONEVNU_TUITION] QR_BACKGROUND | FAILED | '
            'packages/vnu_core/$asset | $error');
        }
        // Do not imitate the user's artwork with a gradient when loading
        // fails. The previous fallback looked close enough to conceal a
        // missing PNG and made troubleshooting almost impossible.
        return const ColoredBox(color: Color(0xFFFAF8F1));
      },
    ),
  );
}

class _TuitionQrOuterCorners extends CustomPainter {
  const _TuitionQrOuterCorners();
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()..color = const Color(0xFF007D59)
      ..strokeWidth = 2.6..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    // The strokes sit on the OUTER EDGE of the padded white QR panel.
    const gap = 4.5;
    const length = 15.0;
    final right = size.width - gap;
    final bottom = size.height - gap;
    canvas.drawLine(const Offset(gap, gap),
      const Offset(gap + length, gap), pen);
    canvas.drawLine(const Offset(gap, gap),
      const Offset(gap, gap + length), pen);
    canvas.drawLine(Offset(right - length, gap), Offset(right, gap), pen);
    canvas.drawLine(Offset(right, gap), Offset(right, gap + length), pen);
    canvas.drawLine(Offset(gap, bottom - length), Offset(gap, bottom), pen);
    canvas.drawLine(Offset(gap, bottom), Offset(gap + length, bottom), pen);
    canvas.drawLine(Offset(right - length, bottom), Offset(right, bottom), pen);
    canvas.drawLine(Offset(right, bottom - length), Offset(right, bottom), pen);
  }
  @override
  bool shouldRepaint(_TuitionQrOuterCorners old) => false;
}

