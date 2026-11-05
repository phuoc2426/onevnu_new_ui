import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_premium_ui.dart';
import 'package:vnu_core/widgets/vnu_loading.dart';

/// A payment QR is bound to a payment-request ID, NOT to status-poll ticks.
/// Reuse the same Uint8List/MemoryImage as long as the gateway QR source stays
/// unchanged. A new image is decoded only after the backend returns a new QR.
/// Never fabricate bank transfer contents from a receivable or amount.
class TuitionStableQr extends StatefulWidget {
  const TuitionStableQr({super.key, required this.request,
    required this.size, required this.placeholderBuilder});

  final TuitionPaymentRequest request;
  final double size;
  final Widget Function(String message) placeholderBuilder;

  @override
  State<TuitionStableQr> createState() => _TuitionStableQrState();
}

class _TuitionStableQrState extends State<TuitionStableQr> {
  String? _cachedRequestId;
  String? _cachedImage;
  String? _cachedPayload;
  Uint8List? _decodedImage;
  String? _decodeError;

  @override
  void initState() {
    super.initState();
    _syncGatewaySource();
  }

  @override
  void didUpdateWidget(covariant TuitionStableQr oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGatewaySource();
  }

  void _syncGatewaySource() {
    final request = widget.request;
    if (_cachedRequestId == request.id &&
        _cachedImage == request.imageBase64 &&
        _cachedPayload == request.payload) {
      return; // GET status changed, but the actual QR is identical.
    }
    _cachedRequestId = request.id;
    _cachedImage = request.imageBase64;
    _cachedPayload = request.payload;
    _decodedImage = null;
    _decodeError = null;
    final image = request.imageBase64;
    if (image == null || image.isEmpty) return;
    try {
      final encoded = image.contains(',') ? image.split(',').last : image;
      _decodedImage = base64Decode(encoded);
    } catch (_) {
      _decodeError = 'Ảnh QR không hợp lệ.';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_decodedImage != null) {
      content = Image.memory(
        _decodedImage!,
        key: const ValueKey<String>('tuition_stable_qr_image'),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        // When the gateway actually rotates its QR, retain the old frame
        // while Flutter decodes the new one; status GET alone never rotates.
        gaplessPlayback: true,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            widget.placeholderBuilder('Không hiển thị được ảnh QR.'),
      );
    } else if (_cachedPayload?.isNotEmpty ?? false) {
      content = QrImageView(
        key: const ValueKey<String>('tuition_stable_qr_payload'),
        data: _cachedPayload!,
        size: widget.size,
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
      );
    } else {
      content = widget.placeholderBuilder(_decodeError ??
          'Ngân hàng chưa trả mã QR cho yêu cầu này.');
    }
    return RepaintBoundary(
      child: SizedBox(width: widget.size, height: widget.size,
        child: content),
    );
  }
}

/// Appears ON TOP of an expired/cancelled QR, never below the scanner frame.
/// The one-shot entrance animation does not restart on each status GET.
class TuitionQrReloadOverlay extends StatelessWidget {
  const TuitionQrReloadOverlay({super.key, required this.onPressed,
    this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.76, end: 1),
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) => Opacity(
      opacity: ((scale - 0.76) / 0.24).clamp(0.0, 1.0),
      child: Transform.scale(scale: scale, child: child),
    ),
    child: Material(color: Colors.transparent,
      child: Semantics(button: true,
        label: 'Tạo lại mã QR đã hết hạn',
        child: InkWell(
          key: const ValueKey<String>('tuition_qr_reload_overlay'),
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 63, height: 63,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TuitionPalette.green,
                  boxShadow: [BoxShadow(color: Color(0x40004C39),
                    blurRadius: 14, offset: Offset(0, 5))],
                ),
                child: Center(child: busy
                  ? VnuLoading.inline(size: 31, color: Colors.white)
                  : const Icon(Icons.refresh_rounded,
                      size: 35, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [BoxShadow(color: Color(0x1C10362A),
                    blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  child: Text(busy ? 'Đang tạo mã...' : 'Tạo lại mã QR',
                    style: const TextStyle(
                      fontFamily: TextStyles.fontName,
                      color: TuitionPalette.deepGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ),
  );
}
