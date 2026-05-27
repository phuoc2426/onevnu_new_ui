import 'package:flutter/material.dart';

class TextStyles {
  static const String fontName = 'OpenSans';

  static const Color textColor = Color(0xff181E39);

  static TextStyle T14M = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textColor,
    height: 1.35,
  );

  static TextStyle T12M = const TextStyle(
    fontFamily: fontName,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textColor,
    height: 1.35,
  );

  static TextStyle light = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle regular = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle medium = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle semiBold = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle bold = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle extraBold = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static TextStyle italic = const TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: textColor,
    fontStyle: FontStyle.italic,
    height: 1.35,
  );
}
