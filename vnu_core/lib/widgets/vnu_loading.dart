import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Animation choices. `random` selects once per show/inline widget build.
enum VnuLoadingType { hourGlassRefined, fadingCircle, threeBounce, random }

class VnuLoadingHandle {
  VnuLoadingHandle._(this._entry, this._close);
  final OverlayEntry _entry;
  final void Function(OverlayEntry) _close;
  bool _closed = false;
  void close() {
    if (_closed) return;
    _closed = true;
    _close(_entry);
  }
}

/// ONEVNU loading giao dien dung chung, khong phu thuoc GetX.
/// `show()`/`hide()` cho callback cu; `during()` hoac ticket.close()
/// dam bao request song song khong tat overlay cua request khac.
class VnuLoading {
  VnuLoading._();
  static final List<VnuLoadingHandle> _handles = <VnuLoadingHandle>[];
  static final Random _random = Random();

  static VnuLoadingType _resolve(VnuLoadingType type) {
    if (type != VnuLoadingType.random) return type;
    final items = <VnuLoadingType>[
      VnuLoadingType.hourGlassRefined,
      VnuLoadingType.fadingCircle,
      VnuLoadingType.threeBounce,
    ];
    return items[_random.nextInt(items.length)];
  }

  static Widget inline({
    VnuLoadingType type = VnuLoadingType.hourGlassRefined,
    Color color = const Color(0xFF087C50),
    double size = 34,
  }) {
    switch (_resolve(type)) {
      case VnuLoadingType.hourGlassRefined:
        return SpinKitPouringHourGlassRefined(color: color, size: size);
      case VnuLoadingType.fadingCircle:
        return SpinKitFadingCircle(color: color, size: size);
      case VnuLoadingType.threeBounce:
        return SpinKitThreeBounce(color: color, size: size);
      case VnuLoadingType.random:
        return SpinKitPouringHourGlassRefined(color: color, size: size);
    }
  }

  static VnuLoadingHandle show(
    BuildContext context, {
    VnuLoadingType type = VnuLoadingType.hourGlassRefined,
    String? message,
    bool modal = true,
  }) {
    final resolved = _resolve(type);
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => Stack(children: [
      if (modal) const Positioned.fill(child: ModalBarrier(
        dismissible: false, color: Color(0x77000000))),
      Center(child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              inline(type: resolved),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 13,
                  color: Color(0xFF17211E))),
              ],
            ]),
          ),
        ),
      )),
    ]));
    late final VnuLoadingHandle handle;
    handle = VnuLoadingHandle._(entry, (target) {
      _handles.remove(handle);
      target.remove();
      target.dispose();
    });
    Overlay.of(context, rootOverlay: true).insert(entry);
    _handles.add(handle);
    return handle;
  }

  /// Legacy convenience. Prefer closing your own handle when concurrent.
  static void hide() {
    if (_handles.isNotEmpty) _handles.last.close();
  }

  static Future<T> during<T>(BuildContext context,
      Future<T> Function() action, {
      VnuLoadingType type = VnuLoadingType.hourGlassRefined,
      String? message,
  }) async {
    final handle = show(context, type: type, message: message);
    try { return await action(); } finally { handle.close(); }
  }
}
