import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vnu_core/themes/app_theme.dart';

class MarkerGenerator {
  final double _markerSize;
  late double _circleStrokeWidth;
  late double _circleOffset;
  late double _outlineCircleWidth;
  late double _fillCircleWidth;
  late double _iconSize;
  late double _iconOffset;

  MarkerGenerator(this._markerSize) {
    // calculate marker dimensions
    _circleStrokeWidth = _markerSize / 10.0;
    _circleOffset = _markerSize / 2;
    _outlineCircleWidth = _circleOffset - (_circleStrokeWidth / 2);
    _fillCircleWidth = _markerSize / 2;
    final outlineCircleInnerWidth = _markerSize - (2 * _circleStrokeWidth);
    _iconSize = sqrt(pow(outlineCircleInnerWidth, 2) / 2);
    final rectDiagonal = sqrt(2 * pow(_markerSize, 2));
    final circleDistanceToCorners =
        (rectDiagonal - outlineCircleInnerWidth) / 2;
    _iconOffset = sqrt(pow(circleDistanceToCorners, 2) / 2);
  }

  Future<BitmapDescriptor> createBitmapDescriptorFromString(String title,
      {required TextStyle textStyle,
      Color backgroundColor = Colors.transparent}) async {
    TextSpan span = TextSpan(
      style: textStyle,
      text: title,
    );
    TextPainter painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.text = TextSpan(
      text: title.toString(),
      style: textStyle,
    );
    PictureRecorder pictureRecorder = PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);
    painter.layout();
    painter.paint(canvas, const Offset(20.0, 10.0));
    int textWidth = painter.width.toInt();
    int textHeight = painter.height.toInt();
    canvas.drawRRect(
        RRect.fromLTRBAndCorners(0, 0, textWidth + 40, textHeight + 20,
            bottomLeft: const Radius.circular(10),
            bottomRight: const Radius.circular(10),
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10)),
        Paint()..color = backgroundColor);
    Picture p = pictureRecorder.endRecording();
    ByteData? pngBytes = await (await p.toImage(
            painter.width.toInt() + 40, painter.height.toInt() + 50))
        .toByteData(format: ImageByteFormat.png);
    Uint8List data = Uint8List.view(pngBytes!.buffer);
    return BitmapDescriptor.fromBytes(data);
  }

  /// Creates a BitmapDescriptor from an IconData
  Future<BitmapDescriptor> createBitmapDescriptorFromIconData(IconData iconData,
      Color iconColor, Color circleColor, Color backgroundColor,
      {bool isShowArrow = true}) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    _paintCircleFill(canvas, backgroundColor);
    _paintCircleStroke(canvas, backgroundColor); // circleColor
    if (isShowArrow) {
      _paintArrow(canvas, backgroundColor);
    }
    _paintIcon(canvas, iconColor, iconData);

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(_markerSize.round(), (_markerSize * 1.3).round());
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    return bytes == null
        ? BitmapDescriptor.fromBytes(Uint8List(0))
        : BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  /// Paints the icon background
  void _paintCircleFill(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(
        Offset(_circleOffset, _circleOffset), _fillCircleWidth, paint);
  }

  /// Paints a circle around the icon
  void _paintCircleStroke(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = _circleStrokeWidth;
    canvas.drawCircle(
        Offset(_circleOffset, _circleOffset), _outlineCircleWidth, paint);
  }

  ///Paints an arrow icon
  void _paintArrow(Canvas canvas, Color color) {
    double bottom = _markerSize.round() * 1.3;
    var arrowPath = Path();
    arrowPath.moveTo(0, _markerSize / 2);
    arrowPath.lineTo(_markerSize, _markerSize / 2);
    arrowPath.lineTo(_markerSize / 2, bottom);
    arrowPath.close();
    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  /// Paints the icon
  void _paintIcon(Canvas canvas, Color color, IconData iconData) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          letterSpacing: 0.0,
          fontSize: _iconSize,
          fontFamily: iconData.fontFamily,
          color: color,
        ));
    textPainter.layout();
    textPainter.paint(canvas, Offset(_iconOffset, _iconOffset));
  }

  void _paintTitle(Canvas canvas, String title) {
    TextSpan span = TextSpan(
      style: AppTheme.body2,
      text: title,
    );
    TextPainter painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.text = TextSpan(
      text: title.toString(),
      style: AppTheme.body2,
    );

    painter.layout();
    painter.paint(canvas, const Offset(20.0, 10.0));
  }
}
