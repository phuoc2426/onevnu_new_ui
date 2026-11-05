import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Draws the VNU printer PNG across the requested destination size.
/// Transparent outer margins are cropped ONCE, so visible printer artwork
/// really fills screenWidth + 40dp rather than only its padded PNG canvas.
class TuitionPrinterArtwork extends StatefulWidget {
  /// Decodes and alpha-crops the PNG outside the first printer animation.
  /// Subsequent artwork widgets clone the cached immutable image handle.
  static Future<void> prewarm({String assetKey =
      'packages/vnu_core/assets/tinktalk/printer_bill.png'}) async {
    try {
      await _TuitionPrinterArtworkState._cached.putIfAbsent(
          assetKey, () => _TuitionPrinterArtworkState._decode(assetKey));
    } catch (_) {
      // The existing fallback artwork will be used if the PNG is missing.
    }
  }

  const TuitionPrinterArtwork({super.key, required this.width,
    required this.height, this.assetKey =
      'packages/vnu_core/assets/tinktalk/printer_bill.png'});

  final double width;
  final double height;
  final String assetKey;

  @override
  State<TuitionPrinterArtwork> createState() => _TuitionPrinterArtworkState();
}

class _TuitionPrinterArtworkState extends State<TuitionPrinterArtwork> {
  static final Map<String, Future<_PrinterRaster>> _cached = {};
  ui.Image? _image;
  ui.Rect? _crop;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant TuitionPrinterArtwork old) {
    super.didUpdateWidget(old);
    if (old.assetKey != widget.assetKey) {
      _image?.dispose();
      _image = null;
      _crop = null;
      _failed = false;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final name = widget.assetKey;
    ui.Image? decoded;
    try {
      final raster = await _cached.putIfAbsent(name, () => _decode(name));
      decoded = raster.image.clone();
      if (!mounted || widget.assetKey != name) {
        decoded.dispose();
        return;
      }
      setState(() { _image = decoded; _crop = raster.crop; });
    } catch (error) {
      _cached.remove(name);
      decoded?.dispose();
      if (!mounted || widget.assetKey != name) return;
      if (kDebugMode) debugPrint('[ONEVNU_TUITION] PRINTER_PNG | MISSING | $name | $error');
      setState(() => _failed = true);
    }
  }

  static Future<_PrinterRaster> _decode(String name) async {
    ui.Image? decoded;
    try {
      final bytes = await rootBundle.load(name);
      // A 1440px crop is enough for a 480dp phone at 3x density. Avoid
      // decoding a large source PNG at full resolution before the first QR.
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        targetWidth: 1440, allowUpscaling: false);
      try {
        final frame = await codec.getNextFrame();
        decoded = frame.image;
      } finally {
        codec.dispose();
      }
      final image = decoded;
      if (image == null) throw StateError('PNG decode produced no image');
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (pixels == null) throw StateError('No RGBA data');
      final rgba = pixels.buffer.asUint8List(
        pixels.offsetInBytes, pixels.lengthInBytes);
      final w = image.width;
      final h = image.height;
      var left = w;
      var right = -1;
      var top = h;
      var bottom = -1;
      // One-time alpha bounding box. No per-frame pixel access or decoding.
      // O(maxDimension^2) bounded alpha sampling, instead of scanning every
      // pixel of a multi-megapixel PNG on the UI isolate. The crop includes
      // a one-sample margin to preserve antialiased edges.
      final scanStep = ((w > h ? w : h) / 850).ceil().clamp(1, 100).toInt();
      for (var y = 0; y < h; y += scanStep) {
        // Yield periodically during alpha trimming, so even on Flutter Web
        // the spinner gets opportunities to draw before the scene is ready.
        if (y > 0 && (y ~/ scanStep) % 70 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        for (var x = 0; x < w; x += scanStep) {
          if (rgba[(y * w + x) * 4 + 3] < 20) continue;
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
      final crop = right < left
        ? ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble())
        : ui.Rect.fromLTRB(
            (left - scanStep).clamp(0, w).toDouble(),
            (top - scanStep).clamp(0, h).toDouble(),
            (right + scanStep + 1).clamp(0, w).toDouble(),
            (bottom + scanStep + 1).clamp(0, h).toDouble());
      return _PrinterRaster(image, crop);
    } catch (_) {
      decoded?.dispose();
      rethrow;
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: widget.width, height: widget.height,
      child: _image != null && _crop != null
        ? CustomPaint(painter: _CroppedPrinterPainter(_image!, _crop!))
        : _failed
          ? const ColoredBox(color: Color(0xFF34443D),
              child: Align(alignment: Alignment.bottomCenter,
                child: SizedBox(height: 8,
                  child: ColoredBox(color: Color(0xFF19251F)))))
          : const SizedBox.shrink());
  }
}

class _CroppedPrinterPainter extends CustomPainter {
  _CroppedPrinterPainter(this.image, this.crop);
  final ui.Image image;
  final ui.Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawImageRect(image, crop,
      Offset.zero & size, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _CroppedPrinterPainter old) =>
    old.image != image || old.crop != crop;
}

class _PrinterRaster {
  const _PrinterRaster(this.image, this.crop);
  final ui.Image image;
  final ui.Rect crop;
}
