import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/widgets/app_update_local_assets.dart';
import 'package:vnu_core/services/app_config_service.dart';

/// A single consistent update chooser for the floating button and the
/// global mandatory/optional update gate. No update icon above the title:
/// Android and iOS icons are the ONLY artwork in the two store cards.
class AppUpdateStoreChooser extends StatefulWidget {
  const AppUpdateStoreChooser({
    super.key,
    this.force = false,
    this.onClose,
    this.message,
  });

  final bool force;
  final VoidCallback? onClose;
  final String? message;

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) => Center(
        child: AppUpdateStoreChooser(
          onClose: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
        ),
      ),
    );
  }

  @override
  State<AppUpdateStoreChooser> createState() => _AppUpdateStoreChooserState();
}

class _AppUpdateStoreChooserState extends State<AppUpdateStoreChooser> {
  bool _launching = false;
  String? _error;

  String _storeUrl({required bool android}) {
    final policy = AppConfigService().appUpdatePolicy;
    final configured = (android
        ? policy?.android.storeUrl
        : policy?.ios.storeUrl) ?? '';
    final parsed = Uri.tryParse(configured.trim());
    if (parsed != null && parsed.scheme == 'https' && parsed.host.isNotEmpty) {
      return parsed.toString();
    }
    // Same verified app IDs as the existing production update service.
    return android ? Utils.androidStoreUrl : Utils.iosStoreUrl;
  }

  Future<void> _openStore({required bool android}) async {
    if (_launching) return;
    setState(() { _launching = true; _error = null; });
    final url = _storeUrl(android: android);
    try {
      final success = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (success) {
        // Close only the user-opened dialog. The force update gate, if any,
        // must remain active until the installed version satisfies the policy.
        if (!widget.force) widget.onClose?.call();
      } else {
        setState(() => _error = 'Không thể mở cửa hàng. Hãy thử lại.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể mở liên kết lúc này.');
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIsAndroid = !kIsWeb && Platform.isAndroid;
    final currentIsIos = !kIsWeb && Platform.isIOS;
    final title = widget.force ? 'Yêu cầu cập nhật' : 'Cập nhật ứng dụng';
    final explanation = widget.message?.trim().isNotEmpty == true
        ? widget.message!.trim()
        : 'Chọn cửa hàng để cập nhật OneVNU';
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 350,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), blurRadius: 32,
              offset: Offset(0, 14)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(child: Text(title,
                style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800, height: 1.2))),
              if (!widget.force)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 21),
                  tooltip: 'Đóng',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.055)),
                ),
            ]),
            const SizedBox(height: 2),
            Text(explanation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5,
                height: 1.35, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 15),
            Row(children: <Widget>[
              Expanded(child: _StoreTile(
                title: 'Android', store: 'Google Play',
                imageFuture: AppUpdateLocalAssets.androidIcon,
                currentPlatform: currentIsAndroid,
                enabled: !_launching,
                onTap: () => _openStore(android: true))),
              const SizedBox(width: 10),
              Expanded(child: _StoreTile(
                title: 'iOS', store: 'App Store',
                imageFuture: AppUpdateLocalAssets.iosIcon,
                currentPlatform: currentIsIos,
                enabled: !_launching,
                onTap: () => _openStore(android: false))),
            ]),
            if (_launching) ...<Widget>[
              const SizedBox(height: 9),
              const Center(child: SizedBox(height: 16, width: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(
                fontSize: 12, color: Color(0xFFC03636))),
            ],
            if (widget.force) ...<Widget>[
              const SizedBox(height: 11),
              const Text('Cần cập nhật ứng dụng để tiếp tục.',
                style: TextStyle(fontSize: 12, color: Color(0xFFAA5933))),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.title,
    required this.store,
    required this.imageFuture,
    required this.currentPlatform,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String store;
  final Future<Uint8List> imageFuture;
  final bool currentPlatform;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: currentPlatform ? const Color(0xFFE8F7ED) : scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: currentPlatform
                ? const Color(0xFF2AAB6C)
                : scheme.outlineVariant, width: currentPlatform ? 1.5 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 43, width: 43,
                child: FutureBuilder<Uint8List>(
                  future: imageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Lỗi ảnh',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10,
                          color: scheme.error));
                    }
                    final bytes = snapshot.data;
                    if (bytes == null) return const SizedBox.shrink();
                    return Image.memory(bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, trace) {
                        if (kDebugMode) debugPrint(
                            '[OneVNU Update] PNG decode failed: $error');
                        return Text('Lỗi ảnh',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10,
                            color: scheme.error));
                      });
                  },
                ),
              ),
              const SizedBox(height: 5),
              Text(title, maxLines: 1,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
              Text(store, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
