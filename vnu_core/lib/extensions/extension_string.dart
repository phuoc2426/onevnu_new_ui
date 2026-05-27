import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:vnu_core/common/convert_utitls.dart';
import 'package:mime/mime.dart';

extension ExtensionString on String {
  int parseInt() {
    if (this == "") {
      return 0;
    }
    int number = 0;
    try {
      number = int.parse(this);
    } on Exception catch (_) {}
    return number;
  }

  int parseImageInt() {
    if (this == "") {
      return 0xe57f;
    }
    int number = 0xe57f;
    try {
      number = int.parse(this);
    } on Exception catch (_) {}
    return number;
  }

  double parseDouble() {
    return double.parse(this);
  }

  bool parseBool() {
    return (toLowerCase() == 'true' || toLowerCase() == '1');
  }

  String fileExtension() {
    return p.extension(this).replaceAll('.', '');
  }

  String noHtml() {
    String parsedstring3 = Bidi.stripHtmlIfNeeded(this);
    return parsedstring3;
  }

  String formNum() {
    return NumberFormat.simpleCurrency(
            locale: 'vi-VN', decimalDigits: 2, name: 'VNĐ')
        .format(
      double.parse(this),
    );
  }

  String toKhongDau() {
    return ConvertString().unsigned(this);
  }

  /// Check by name and extension
  bool isVideo() {
    String? mimeType = lookupMimeType(this);
    if (mimeType?.contains('video') == true) {
      return true;
    }
    return false;
  }

  bool isImage() {
    String? mimeType = lookupMimeType(this);
    if (mimeType?.contains('image') == true) {
      return true;
    }
    return false;
  }
}

extension StringTruongChinh on String {
  String toDisplayName() {
    if (this == 'TruongChinh') {
      return 'Trường Chính';
    }
    if (this == 'BangKep') {
      return 'Bằng Kép';
    }
    if (this == 'TruongGui') {
      return 'Trường Gửi';
    }
    return this;
  }
}
