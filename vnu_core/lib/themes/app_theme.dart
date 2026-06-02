import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  //Background color
  static const Color nearlyWhite = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF6F9FE);
  static const Color backgroundBlueColor = Color(0xFF003392);
  static const Color dismissibleBackground = Color(0xFF364A54);
  static const Color spacer = Color(0xFFF2F2F2);
  static const Color borderColor = Color(0xFFD6DADE);

  static const String fontName = 'OpenSans';

  static const Color textTitleColor = Color(0xff212944);
  static const Color textHighLightColor = Color(0xff4188F1);
  static const Color textColor = Color(0xff2A3556);
  static const Color textSubColor = Color(0xff777B89);

  static const colorWarning = Color(0xFFF89C23);
  static const colorError = Colors.red;
  static const colorSuccess = Color(0xFF43A047);

  //Color Menu
  static const colorMain = Color(0xFF007F3E);
  static const colorInActive = Color(0xFFD5DAD9);
  static const colorLine = Color(0xFFCAD5E0);
  static const colorIconBottomBar = Color(0xFF817979);
  static const colorTextMain = Color(0xFF2A3556);
  static const colorTextCountNotification = Color(0xFFFF6B6B);
  static const colorIconLeft = Color(0xFF979AA5);
  static const colorIcon = Color(0xFF28283A);
  static const colorMenuActive = Color(0xFFDAE6F6);
  static const colorGreylineBorder = Color(0xFFD6DADE);
  static const colorLightBlue = Color(0xFF4188F1);
  static const Color activeGreen = Color(
    0xFF22C55E,
  ); // https://material.io/design/typography/the-type-system.html#type-scale
  // static const TextTheme textTheme = TextTheme(
  //   headline1: headline1,
  //   headline2: headline2,
  //   headline3: headline3,
  //   headline4: headline4,
  //   headline5: headline5,
  //   headline6: headline6,
  //   subtitle1: subtitle1,
  //   subtitle2: subtitle2,
  //   bodyText2: body2,
  //   bodyText1: body1,
  //   caption: caption,
  // );

  static const TextStyle display1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: AppFontSizes.font36,
    letterSpacing: 0.4,
    height: 1.35,
    color: textColor,
  );

  static const TextStyle headline1 = TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.font96,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    height: 1.35,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.font60,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    height: 1.35,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.font48,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const TextStyle headline4 = TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.font34,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.35,
  );

  static const TextStyle headline5 = TextStyle(
    fontFamily: fontName,
    fontSize: AppFontSizes.font24,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const TextStyle headline6 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSizes.font24,
    letterSpacing: 0.27,
    color: textColor,
    height: 1.35,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.normal,
    fontSize: AppFontSizes.large,
    letterSpacing: 0.15,
    color: textColor,
    height: 1.35,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSizes.medium,
    letterSpacing: 0.1,
    color: textColor,
    height: 1.35,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.normal,
    fontSize: AppFontSizes.large,
    letterSpacing: 0.5,
    color: textColor,
    height: 1.35,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.normal,
    fontSize: AppFontSizes.medium,
    letterSpacing: 0.25,
    color: textColor,
    height: 1.35,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSizes.medium,
    letterSpacing: 1.25,
    color: textColor, // was lightText
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.normal,
    fontSize: AppFontSizes.small,
    letterSpacing: 0.4,
    color: textColor, // was lightText
    height: 1.35,
  );
  static const TextStyle common = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.normal,
    fontSize: AppFontSizes.medium,
    color: Colors.black,
    height: 1.35,
  );
}
