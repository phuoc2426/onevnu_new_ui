import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/modules/tuition/data/tuition_demo_repository.dart';
import 'package:vnu_core/widgets/vnu_loading.dart';

/// A restrained palette for the ONEVNU tuition flow. All values are shared by
/// overview and payment detail; the global ONEVNU AppBar remains unchanged.
abstract final class TuitionPalette {
  static const Color canvas = Color(0xFFFAF8F1);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF0D2C24);
  static const Color muted = Color(0xFF738078);
  static const Color subdued = Color(0xFF97A19B);
  static const Color line = Color(0xFFE8ECE9);
  static const Color green = Color(0xFF007D59);
  static const Color deepGreen = Color(0xFF064C3C);
  static const Color greenSoft = Color(0xFFEAF5EF);
}

/// User-supplied icons: payment_icons/<name>.png. Existing icons in
/// module_details/<name>.png remain supported as a non-breaking fallback.
class TuitionArtIcon extends StatelessWidget {
  const TuitionArtIcon({super.key, required this.name, required this.fallback,
    this.size = 24, this.color = TuitionPalette.green});

  final String name;
  final IconData fallback;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icons/payment_icons/$name.png', package: 'vnu_core',
    width: size, height: size, fit: BoxFit.contain, gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) => Image.asset(
      'assets/icons/module_details/$name.png', package: 'vnu_core',
      width: size, height: size, fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
        Icon(fallback, size: size, color: color),
    ),
  );
}

class TuitionStatusPresentation {
  const TuitionStatusPresentation({required this.label,
    required this.description, required this.icon,
    required this.fallbackIcon, required this.color,
    required this.background, required this.dimQr,
    required this.allowRecreate, required this.watch});

  final String label;
  final String description;
  final String icon;
  final IconData fallbackIcon;
  final Color color;
  final Color background;
  final bool dimQr;
  final bool allowRecreate;
  final bool watch;

  static TuitionStatusPresentation from(TuitionPaymentStatus status) => switch(status) {
    TuitionPaymentStatus.pending => const TuitionStatusPresentation(
      label: 'Chờ thanh toán',
      description: 'Quét mã QR để hoàn tất khoản thu.',
      icon: 'tuition_status_pending', fallbackIcon: Icons.schedule_rounded,
      color: Color(0xFFA46B13), background: Color(0xFFFFF6E5),
      dimQr: false, allowRecreate: false, watch: true),
    TuitionPaymentStatus.processing => const TuitionStatusPresentation(
      label: 'Đang giao dịch',
      description: 'Đang chờ ngân hàng xác nhận giao dịch.',
      icon: 'tuition_status_processing', fallbackIcon: Icons.sync_rounded,
      color: Color(0xFF1F649E), background: Color(0xFFECF4FD),
      dimQr: true, allowRecreate: false, watch: true),
    TuitionPaymentStatus.paid => const TuitionStatusPresentation(
      label: 'Đã thanh toán',
      description: 'Hệ thống đã xác nhận thanh toán.',
      icon: 'tuition_status_paid', fallbackIcon: Icons.check_circle_outline_rounded,
      color: Color(0xFF08794D), background: Color(0xFFEAF5EF),
      dimQr: true, allowRecreate: false, watch: false),
    TuitionPaymentStatus.expired => const TuitionStatusPresentation(
      label: 'Mã hết hạn',
      description: 'Mã QR này không còn hiệu lực.',
      icon: 'tuition_status_expired', fallbackIcon: Icons.timer_off_outlined,
      color: Color(0xFF995F26), background: Color(0xFFFFF4E9),
      dimQr: true, allowRecreate: true, watch: false),
    TuitionPaymentStatus.cancelled => const TuitionStatusPresentation(
      label: 'Đã hủy',
      description: 'Yêu cầu thanh toán đã bị hủy.',
      icon: 'tuition_status_cancelled', fallbackIcon: Icons.cancel_outlined,
      color: Color(0xFF9A5050), background: Color(0xFFFBEEEE),
      dimQr: true, allowRecreate: true, watch: false),
  };
}

class TuitionStatusCard extends StatelessWidget {
  const TuitionStatusCard({super.key, required this.status,
    this.lastUpdated, this.provider, this.refreshing = false,
    this.onRefresh, this.labelOverride, this.descriptionOverride});

  final TuitionPaymentStatus status;
  final DateTime? lastUpdated;
  final String? provider;
  final bool refreshing;
  final VoidCallback? onRefresh;
  final String? labelOverride;
  final String? descriptionOverride;

  @override
  Widget build(BuildContext context) {
    final data = TuitionStatusPresentation.from(status);
    final updated = lastUpdated == null ? null : DateFormat('HH:mm').format(lastUpdated!);
    final providerValue = provider?.trim();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: data.background,
        borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 28, height: 28,
          child: Center(child: refreshing && data.watch
            ? VnuLoading.inline(size: 22, color: data.color)
            : TuitionArtIcon(name: data.icon, fallback: data.fallbackIcon,
                size: 25, color: data.color))),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
          Text(labelOverride ?? data.label, style: TextStyle(fontFamily: TextStyles.fontName, color: data.color,
            fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.25)),
          if (descriptionOverride != null && descriptionOverride!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(descriptionOverride!, maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: TextStyles.fontName, color: data.color, fontSize: 10.5,
                fontWeight: FontWeight.w500)),
          ],
          if (status == TuitionPaymentStatus.processing &&
              (updated != null || (providerValue != null && providerValue.isNotEmpty))) ...[
            const SizedBox(height: 5),
            Text([
              if (providerValue != null && providerValue.isNotEmpty) providerValue,
              if (updated != null) 'Cập nhật $updated',
            ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: TextStyles.fontName, color: data.color, fontSize: 10.5,
                fontWeight: FontWeight.w600)),
          ],
        ])),
        if (onRefresh != null && data.watch) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Kiểm tra trạng thái ngay',
            onPressed: refreshing ? null : onRefresh,
            icon: Icon(Icons.refresh_rounded, color: data.color, size: 21),
          ),
        ],
      ]),
    );
  }
}

class TuitionSectionHeading extends StatelessWidget {
  const TuitionSectionHeading(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(text, style: const TextStyle(fontFamily: TextStyles.fontName, 
      color: TuitionPalette.ink, fontSize: 15.5,
      fontWeight: FontWeight.w800, letterSpacing: -0.4))),
    if (trailing != null) trailing!,
  ]);
}

class TuitionDetailInfoLine extends StatelessWidget {
  const TuitionDetailInfoLine({super.key, required this.label,
    required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(border: last ? null : const Border(
      bottom: BorderSide(color: TuitionPalette.line))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 4, child: Text(label, style: const TextStyle(fontFamily: TextStyles.fontName, 
        fontSize: 10.5, color: TuitionPalette.muted, height: 1.3))),
      const SizedBox(width: 6),
      Expanded(flex: 6, child: Text(value, textAlign: TextAlign.end,
        style: const TextStyle(fontFamily: TextStyles.fontName, color: TuitionPalette.ink, fontSize: 11.5,
          fontWeight: FontWeight.w600, height: 1.45))),
    ]),
  );
}
