import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_printer_artwork.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

/// Time budgets govern VISUAL warmup only, never HTTP payment/QR timeouts.
/// No minimum loading duration: already-warm assets proceed immediately.
abstract final class TuitionScenePreparationConfig {
  static const Duration entryMaxWait = Duration(milliseconds: 1300);
  static const Duration printerMaxWait = Duration(milliseconds: 550);
}

/// Allows a pending warmup to continue quietly after its UI deadline.
/// A timeout is NOT an exception and never blocks creating/checking QR.
abstract final class TuitionWarmupDeadline {
  static Future<bool> wait(Future<void> preparation, Duration maximum) async {
    if (maximum <= Duration.zero) return false;
    try {
      await preparation.timeout(maximum);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// One shared scene-preparation pipeline per isolate/browser tab.
/// Subsequent QR attempts reuse image/metrics Futures rather than decoding
/// masks, trimming printer PNG, or allocating the page background again.
abstract final class TuitionScenePreloader {
  static Future<void>? _assets;
  static Future<void>? _background;

  static Future<void> _warmAssets() => _assets ??= _buildAssets();

  static Future<void> _buildAssets() async {
    // Stagger the two alpha scans and the printer decode. Running all three
    // expensive RGBA copies in the SAME initial frame caused visible stalls.
    await TuitionTicketPaper.prewarmMask(TuitionTicketKind.list);
    await Future<void>.delayed(const Duration(milliseconds: 8));
    await TuitionTicketPaper.prewarmMask(TuitionTicketKind.detail);
    await Future<void>.delayed(const Duration(milliseconds: 8));
    await TuitionPrinterArtwork.prewarm();
  }

  static Future<void> _warmBackground(BuildContext context) =>
      _background ??= _cacheBackground(context);

  static Future<void> _cacheBackground(BuildContext context) async {
    try {
      // Decode the detail-page backdrop into Flutter's image cache before
      // entering its animation. Missing artwork retains the app's fallback.
      await precacheImage(
        const AssetImage('assets/tinktalk/background_qr.png',
          package: 'vnu_core'),
        context,
        onError: (Object _, StackTrace? __) {},
      );
    } catch (_) {
      // The production background widget already handles missing assets.
    }
  }

  static Future<bool> ensureReady(BuildContext context, {
    required Duration maximum,
  }) => TuitionWarmupDeadline.wait(Future.wait<void>(<Future<void>>[
      _warmAssets(), _warmBackground(context),
    ]), maximum);
}

/// Cheap loading layer; deliberately avoids BackdropFilter and elaborate
/// Lottie shaders while we are preparing expensive PNG/mask raster resources.
class TuitionScenePreparationOverlay extends StatelessWidget {
  const TuitionScenePreparationOverlay({super.key, this.entering = false});
  final bool entering;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: AbsorbPointer(
      absorbing: true,
      child: ColoredBox(
        color: entering ? const Color(0xFFFAF8F1) : const Color(0xE9FAF8F1),
        child: Center(child: Semantics(
          label: entering ? 'Đang chuẩn bị giao diện học phí' :
              'Đang chuẩn bị hiệu ứng hóa đơn',
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            const SizedBox(width: 30, height: 30,
              child: CircularProgressIndicator(
                color: Color(0xFF007A59), strokeWidth: 2.3)),
            const SizedBox(height: 13),
            Text(entering ? 'Đang chuẩn bị giao diện…' :
                'Đang chuẩn bị hiệu ứng…',
              style: const TextStyle(
                color: Color(0xFF56746A), fontSize: 12.5,
                fontWeight: FontWeight.w600)),
          ]),
        )),
      ),
    ),
  );
}
