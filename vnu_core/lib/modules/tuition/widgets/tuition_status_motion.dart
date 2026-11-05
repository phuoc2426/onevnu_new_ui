import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vnu_core/modules/tuition/data/tuition_api_diagnostics.dart';
import 'package:vnu_core/modules/tuition/data/tuition_demo_repository.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_premium_ui.dart';

/// Plays actual Lottie JSON supplied under the vnu_core package asset bundle.
/// Any missing/broken asset falls back to an icon, but now emits a DEBUG trace.
/// It is NOT sufficient to have a JSON on disk: vnu_core/pubspec.yaml must
/// declare the directory and flutter pub get + a full restart are required.
class TuitionStatusMotion extends StatelessWidget {
  const TuitionStatusMotion({super.key, this.status, this.wallet = false,
    this.size = 45});
  final TuitionPaymentStatus? status;
  final bool wallet;
  final double size;

  static final Set<String> _reportedLoaded = <String>{};
  static final Set<String> _reportedFailed = <String>{};

  static String assetFor(TuitionPaymentStatus? status, {bool wallet = false}) {
    if (wallet) return 'wallet.json';
    return switch (status) {
      TuitionPaymentStatus.pending => 'waiting.json',
      TuitionPaymentStatus.processing => 'processing.json',
      TuitionPaymentStatus.paid => 'success.json',
      TuitionPaymentStatus.expired => 'expire.json',
      TuitionPaymentStatus.cancelled => 'cancel.json',
      null => 'wallet.json',
    };
  }

  @override
  Widget build(BuildContext context) {
    final file = assetFor(status, wallet: wallet);
    final presentation = status == null
        ? null : TuitionStatusPresentation.from(status!);
    final fallback = Icon(
      presentation?.fallbackIcon ?? Icons.account_balance_wallet_rounded,
      size: size * 0.72,
      color: presentation?.color ?? TuitionPalette.green,
    );
    return SizedBox(width: size, height: size,
      child: RepaintBoundary(child: Lottie.asset(
        'assets/icons/animation_icons/$file',
        key: ValueKey<String>('vnu_core/tuition/$file'),
        package: 'vnu_core',
        fit: BoxFit.contain,
        animate: true,
        repeat: wallet || status == TuitionPaymentStatus.pending ||
            status == TuitionPaymentStatus.processing,
        onLoaded: (composition) {
          if (kDebugMode && _reportedLoaded.add(file)) {
            TuitionApiDiagnostics.instance.record('LOTTIE', 'LOADED',
              note: file);
          }
        },
        errorBuilder: (context, error, stack) {
          if (kDebugMode && _reportedFailed.add(file)) {
            TuitionApiDiagnostics.instance.record('LOTTIE', 'FAILED',
              note: file);
            debugPrint('[ONEVNU_TUITION] LOTTIE asset failed ($file): '
                '$error');
          }
          return Center(child: fallback);
        },
      )),
    );
  }
}
