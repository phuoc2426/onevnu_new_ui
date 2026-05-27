import 'package:flutter/material.dart';

class VcoreGreenBrandV3 {
  VcoreGreenBrandV3._();

  static const Color brand = Color(0xFF16A34A);
  static const Color brandSoft = Color(0xFFEAF8EF);
  static const Color hover = Color(0xFF4ADE80);
  static const Color background = Color(0xFFF7F8F7);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF1F3F2);
  static const Color nearBlack = Color(0xFF0A0B0D);
  static const Color darkCard = Color(0xFF282B31);
  static const Color muted = Color(0xFF5B616E);
  static const Color border = Color(0xFFE4E7E5);
  static const Color line = Color(0xFFF0F1F0);
  static const Color successSoft = Color(0xFFE9F9EE);

  static BoxShadow softShadow = const BoxShadow(
    color: Color(0x0D0A0B0D),
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  static BoxDecoration cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: [softShadow],
    );
  }
}
