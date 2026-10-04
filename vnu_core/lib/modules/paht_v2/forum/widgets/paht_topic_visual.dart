import 'package:flutter/material.dart';

class PahtTopicVisual {
  final Color color;
  final Color softColor;
  final IconData icon;

  const PahtTopicVisual({
    required this.color,
    required this.softColor,
    required this.icon,
  });
}

PahtTopicVisual pahtTopicVisual({int? topicId, String topicName = ''}) {
  final String name = topicName.toLowerCase().trim();

  if (name.contains('an ninh') || name.contains('an toàn')) {
    return const PahtTopicVisual(
      color: Color(0xFF2374E1),
      softColor: Color(0xFFEAF3FF),
      icon: Icons.shield_outlined,
    );
  }
  if (name.contains('wifi') ||
      name.contains('mạng') ||
      name.contains('công nghệ') ||
      name.contains('internet')) {
    return const PahtTopicVisual(
      color: Color(0xFFF59E0B),
      softColor: Color(0xFFFFF5DE),
      icon: Icons.wifi_rounded,
    );
  }
  if (name.contains('môi trường') ||
      name.contains('rác') ||
      name.contains('vệ sinh')) {
    return const PahtTopicVisual(
      color: Color(0xFF16A34A),
      softColor: Color(0xFFEAF8EF),
      icon: Icons.eco_outlined,
    );
  }
  if (name.contains('giao thông') ||
      name.contains('bãi xe') ||
      name.contains('xe')) {
    return const PahtTopicVisual(
      color: Color(0xFFEF4444),
      softColor: Color(0xFFFFECEC),
      icon: Icons.directions_car_outlined,
    );
  }
  if (name.contains('ký túc') || name.contains('ktx') || name.contains('nội trú')) {
    return const PahtTopicVisual(
      color: Color(0xFF8B5CF6),
      softColor: Color(0xFFF2ECFF),
      icon: Icons.apartment_rounded,
    );
  }
  if (name.contains('cơ sở') ||
      name.contains('thiết bị') ||
      name.contains('điện') ||
      name.contains('nước')) {
    return const PahtTopicVisual(
      color: Color(0xFF0891B2),
      softColor: Color(0xFFE6F8FC),
      icon: Icons.handyman_outlined,
    );
  }
  if (name.contains('đào tạo') ||
      name.contains('học') ||
      name.contains('thi') ||
      name.contains('trường')) {
    return const PahtTopicVisual(
      color: Color(0xFF009B5A),
      softColor: Color(0xFFE8F7F0),
      icon: Icons.school_outlined,
    );
  }

  const List<PahtTopicVisual> palette = <PahtTopicVisual>[
    PahtTopicVisual(
      color: Color(0xFF0F766E),
      softColor: Color(0xFFE8F6F4),
      icon: Icons.label_outline_rounded,
    ),
    PahtTopicVisual(
      color: Color(0xFF7C3AED),
      softColor: Color(0xFFF2EBFF),
      icon: Icons.label_outline_rounded,
    ),
    PahtTopicVisual(
      color: Color(0xFFBE5B00),
      softColor: Color(0xFFFFF0E0),
      icon: Icons.label_outline_rounded,
    ),
    PahtTopicVisual(
      color: Color(0xFF0369A1),
      softColor: Color(0xFFE8F5FB),
      icon: Icons.label_outline_rounded,
    ),
    PahtTopicVisual(
      color: Color(0xFFB4236C),
      softColor: Color(0xFFFFEAF4),
      icon: Icons.label_outline_rounded,
    ),
  ];
  final int index = ((topicId ?? name.hashCode).abs()) % palette.length;
  return palette[index];
}
