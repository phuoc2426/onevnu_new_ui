import 'package:flutter/material.dart';

class AppShowcaseStyle {
  const AppShowcaseStyle({
    this.primaryColor = const Color(0xFF047747),
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.58,
    this.blurValue = 1.2,
    this.tooltipWidth = 310,
    this.tooltipRadius = 22,
    this.backgroundColor = Colors.white,
    this.titleColor = const Color(0xFF111827),
    this.descriptionColor = const Color(0xFF4B5563),
    this.badgeBackgroundColor,
    this.badgeTextColor,
    this.showIcon = true,
    this.showProgress = true,
  });

  final Color primaryColor;
  final Color overlayColor;
  final double overlayOpacity;
  final double blurValue;
  final double tooltipWidth;
  final double tooltipRadius;
  final Color backgroundColor;
  final Color titleColor;
  final Color descriptionColor;
  final Color? badgeBackgroundColor;
  final Color? badgeTextColor;
  final bool showIcon;
  final bool showProgress;

  factory AppShowcaseStyle.home() {
    return const AppShowcaseStyle(
      primaryColor: Color(0xFF047747),
      overlayOpacity: 0.58,
      blurValue: 1.2,
      tooltipWidth: 310,
      tooltipRadius: 22,
    );
  }
}
