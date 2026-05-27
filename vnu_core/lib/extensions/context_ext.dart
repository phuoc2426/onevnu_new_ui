import 'package:flutter/cupertino.dart';

extension ExtensionContext on BuildContext {
  double kWidth() {
    return MediaQuery.of(this).size.width;
  }

  double kHeight() {
    return MediaQuery.of(this).size.height;
  }

  double kHeightTop() {
    return MediaQuery.of(this).padding.top;
  }

  double kHeightBottom() {
    return MediaQuery.of(this).padding.bottom;
  }
}
