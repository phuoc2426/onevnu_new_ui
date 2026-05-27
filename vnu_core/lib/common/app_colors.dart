import 'package:flutter/material.dart';

/// ╔═══════════════════════════════════════════════════════════╗
/// ║  OneVNU Design System – Clean White + Green Accent        ║
/// ║  Modern light UI with dark sidebar                        ║
/// ╚═══════════════════════════════════════════════════════════╝
class AppColors {
  AppColors._();

  // ── Primary palette (Green #2F9E44) ──
  static const primary = Color(0xFF2F9E44);
  static const primaryDark = Color(0xFF237B35);
  static const primaryLight = Color(0xFFEBFBEE);
  static const accent = Color(0xFF51CF66);

  // ── Secondary / highlight ──
  static const secondary = Color(0xFF4263EB);
  static const secondaryLight = Color(0xFFDBE4FF);

  // ── Surfaces — trắng sạch ──
  static const surface = Colors.white;
  static const card = Colors.white;
  static const scaffoldBg = Colors.white;
  static const shimmer = Color(0xFFF1F3F5);

  // ── Text ──
  static const textTitle = Color(0xFF212529);
  static const textPrimary = Color(0xFF343A40);
  static const textSecondary = Color(0xFF868E96);
  static const textHint = Color(0xFFADB5BD);
  static const textOnPrimary = Colors.white;

  // ── Borders / Dividers ──
  static const divider = Color(0xFFE9ECEF);
  static const border = Color(0xFFDEE2E6);
  static const borderLight = Color(0xFFF1F3F5);

  // ── Semantic ──
  static const success = Color(0xFF2F9E44);
  static const warning = Color(0xFFF59F00);
  static const error = Color(0xFFF03E3E);
  static const info = Color(0xFF339AF0);

  // ── Schedule cards — linear gradient light ──
  static const classCardBg = Color(0xFFEBFBEE);
  static const classCardBorder = Color(0xFFD3F9D8);
  static const classCardText = Color(0xFF2B8A3E);
  static const examCardBg = Color(0xFFFFF4E6);
  static const examCardBorder = Color(0xFFFFE8CC);
  static const examCardText = Color(0xFFE8590C);

  // ── Notification / Badge ──
  static const notifyOrange = Color(0xFFE8590C);
  static const notifyOrangeBg = Color(0xFFFFF4E6);
  static const notifyBlueBg = Color(0xFFDBE4FF);
  static const notifyBlue = Color(0xFF4263EB);

  // ── Sidebar — tối hẳn, chữ xanh lá #2F9E44 ──
  static const sidebarBg = Color(0xFF1A1B1E);
  static const sidebarAccent = Color(0xFF2F9E44);
  static const sidebarText = Color(0xFFE9ECEF);
  static const sidebarTextDim = Color(0xFF5C5F66);
  static const sidebarCardBg = Color(0xFF25262B);

  // ── Card gradient (giống ảnh mẫu: nền trắng → xanh nhạt) ──
  static const cardGradientStart = Colors.white;
  static const cardGradientEnd = Color(0xFFF0F9FF); // ice-blue tint
  static const cardGradientGreen = Color(0xFFF0FFF4); // mint tint
  static const cardGradientWarm = Color(0xFFFFF9F0); // warm peach tint

  // ── Shadows — nhẹ nhàng trên nền trắng ──
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 12,
    offset: const Offset(0, 2),
  );

  static BoxShadow cardShadowMd = BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  static BoxShadow cardShadowLg = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 28,
    offset: const Offset(0, 8),
  );

  // ── Unified Palette Extensions (Moving inline colors to AppColors) ──
  static const greenAccent = Color(0xff16a34a);
  static const greenAccentDark = Color(0xff15803d);
  static const greenAccentShadow = Color(0x3316a34a);
  static const orangeAccent = Color(0xfff59e0b);
  static const blueAccent = Color(0xff3b82f6);
  static const todayBlueBg = Color(0xffe8f4ff);
  static const calendarBorder = Color(0xffe2e8f0);
  static const calendarExamBorder = Color(0xfffef3c7);
  
  // Warning Box colors
  static const warningBoxBg = Color(0xffFFF3E0);
  static const warningBoxBorder = Color(0xffFFE0B2);
  static const warningBoxText = Color(0xffE65100);

  // Dimension level/Grade Colors
  static const gradeVeryStrong = Color(0xff00803D);
  static const gradeStrong = Color(0xff2E7D32);
  static const gradeFair = Color(0xffF57C00);
  static const gradeAverage = Color(0xffEF6C00);
  static const gradeWeak = Color(0xffD32F2F);

  // Course Points Detail Colors
  static const darkBlueAccent = Color(0xff003392);
  static const lightGreyBg = Color(0xffF6F6F6);
  static const slateText = Color(0xff637392);
  static const dropdownBorder = Color(0xff879ABF);
  static const darkNavy = Color(0xFF111B3D);
  static const textMuted = Color(0xff8E8E8E);
  static const publishGreen = Color(0xff118A40);

  // Home News Block Colors
  static const brandGreen = Color(0xFF047747);
  static const activeGreenSoft = Color(0xFFE7F5EE);
  static const schoolNewsAccent = Color(0xFF059669);
  static const vnuNewsAccent = Color(0xFF2563EB);

  // ── Home Overview Card Colors ──
  static const overviewGreen = Color(0xFF16a34a);
  static const overviewGreenBg = Color(0xFFDCFCE7);
  static const overviewOrange = Color(0xFFf59e0b);
  static const overviewOrangeBg = Color(0xFFFEF3C7);
  static const overviewBlue = Color(0xFF3b82f6);
  static const overviewBlueBg = Color(0xFFDBEAFE);
  static const overviewPurple = Color(0xFF8b5cf6);
  static const overviewPurpleBg = Color(0xFFEDE9FE);

  // ── Home General ──
  static const homeBg = Color(0xFFF5F8F7);
  static const homeCardBg = Color(0xFFF5F8F7);
  static const homeCardBorder = Color(0xFFE5E7EB);
  static const homeTextTitle = Color(0xFF111827);
  static const homeTextSub = Color(0xFF66708B);
  static const homeTextBody = Color(0xFF172033);
  static const homeRedWeekend = Color(0xFFEF4444);
  static const homeSeparator = Color(0xFFE5E7EB);
  static const homeTimelineLine = Color(0xFFD1D5DB);
}

