import 'package:flutter/material.dart';

enum VnuPageWidth { form, content, wide, unrestricted }

class VnuPageConstraints extends StatelessWidget {
  const VnuPageConstraints({
    super.key,
    required this.child,
    this.width = VnuPageWidth.content,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final VnuPageWidth width;
  final Alignment alignment;

  double get _maxWidth {
    switch (width) {
      case VnuPageWidth.form:
        return 720;
      case VnuPageWidth.content:
        return 900;
      case VnuPageWidth.wide:
        return 1180;
      case VnuPageWidth.unrestricted:
        return double.infinity;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (width == VnuPageWidth.unrestricted) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
