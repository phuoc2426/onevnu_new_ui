import 'package:flutter/material.dart';

class AppFontSizes {
  AppFontSizes._();

  // --- Semantic Scale ---
  static const double extraExtraSmall = 9.0;
  static const double extraSmall = 10.0;
  static const double small = 12.0;
  static const double mediumSmall = 13.0;
  static const double medium = 14.0;
  static const double mediumLarge = 15.0;
  static const double large = 16.0;
  static const double extraLarge = 18.0;
  static const double extraExtraLarge = 20.0;

  // --- Short Semantic Scale (Aliases) ---
  static const double xxs = extraExtraSmall;
  static const double xs = extraSmall;
  static const double sm = small;
  static const double mdSm = mediumSmall;
  static const double md = medium;
  static const double mdLg = mediumLarge;
  static const double lg = large;
  static const double xl = extraLarge;
  static const double xxl = extraExtraLarge;

  // --- Precise Numeric Definitions (For fallback or precise requirements) ---
  static const double font9 = 9.0;
  static const double font10 = 10.0;
  static const double font10_5 = 10.5;
  static const double font11 = 11.0;
  static const double font11_5 = 11.5;
  static const double font12 = 12.0;
  static const double font12_5 = 12.5;
  static const double font12_8 = 12.8;
  static const double font13 = 13.0;
  static const double font13_5 = 13.5;
  static const double font14 = 14.0;
  static const double font14_5 = 14.5;
  static const double font15 = 15.0;
  static const double font15_5 = 15.5;
  static const double font16 = 16.0;
  static const double font17 = 17.0;
  static const double font18 = 18.0;
  static const double font19 = 19.0;
  static const double font20 = 20.0;
  static const double font24 = 24.0;
  static const double font28 = 28.0;
  static const double font34 = 34.0;
  static const double font36 = 36.0;
  static const double font48 = 48.0;
  static const double font60 = 60.0;
  static const double font96 = 96.0;
}

class TextStyles {
  static const String fontName = 'OpenSans';

  static const Color textColor = Color(0xff181E39);

  // --- Core Semantic Font Styles (Requested by User) ---
  
  // 1. Font cho text thường (Regular Text) - font trung bình (14.0)
  static TextStyle regularText = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  // 2. Font cho span chữ bé mờ (Small/Dimmed Text Span)
  static TextStyle smallMuted = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: Color(0xFF868E96), // Muted grey
    height: 1.35,
  );

  // 3. Font cho tên bôi đậm header nổi bật (Bold Header Title)
  static TextStyle headerBold = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.large,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  // --- Existing Legacy Styles (Refactored to use AppFontSizes) ---

  static TextStyle T14M = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w500,
    color: textColor,
    height: 1.35,
  );

  static TextStyle T12M = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.w500,
    color: textColor,
    height: 1.35,
  );

  static TextStyle light = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle regular = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle medium = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle semiBold = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle bold = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle extraBold = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle italic = const TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: textColor,
    fontStyle: FontStyle.italic,
    height: 1.35,
  );
}
