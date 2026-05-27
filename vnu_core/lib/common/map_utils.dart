// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'dart:ui' as ui;
// import 'package:vnu_core/themes/app_theme.dart';

// Future<Uint8List> getBytesFromCanvas(
//     BuildContext context, String text, bool isSelected,
//     {String? iconImage}) async {
//   print(text);

//   final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//   final Canvas canvas = Canvas(pictureRecorder);

//   final Paint shadowPaint = Paint()
//     ..color = Colors.black.withAlpha(40)
//     ..maskFilter = MaskFilter.blur(BlurStyle.normal, convertRadiusToSigma(3));

//   final Paint backgroundPaint = Paint();
//   Color textColor;

//   if (isSelected) {
//     backgroundPaint.color = Colors.amber;
//     textColor = Colors.white;
//   } else {
//     backgroundPaint.color = Colors.white;
//     textColor = AppTheme.textColor;
//   }

//   final int borderWidth = (1 * MediaQuery.of(context).devicePixelRatio).toInt();
//   final int textMargin = 8 * MediaQuery.of(context).devicePixelRatio.toInt();
//   final goldWidth = 16 * MediaQuery.of(context).devicePixelRatio;
//   final textSize = 14 * MediaQuery.of(context).devicePixelRatio;

//   TextPainter pricePainter = TextPainter(
//       textDirection: TextDirection.ltr, textAlign: TextAlign.center);
//   pricePainter.text = TextSpan(
//       text: text,
//       style: TextStyle(
//           fontSize: textSize, color: textColor, fontWeight: FontWeight.bold));
//   pricePainter.layout();

//   double parentWidth = pricePainter.width + textMargin * 2 + borderWidth;
//   final parentHeight = pricePainter.height + textMargin * 2 + borderWidth;

//   // if (iconImage != null) {
//   //   final image = await rootBundle.load(iconImage);
//   //   goldPropertyImage = await loadUiImage(Uint8List.view(image.buffer));
//   // }

//   parentWidth = parentWidth + goldWidth + textMargin;

//   canvas.drawRRect(
//       RRect.fromRectAndRadius(
//           Rect.fromPoints(
//               Offset(borderWidth.toDouble(), borderWidth.toDouble()),
//               Offset(parentWidth + borderWidth, parentHeight + borderWidth)),
//           Radius.circular((parentHeight + 1) / 2)),
//       shadowPaint);

//   canvas.drawRRect(
//       RRect.fromRectAndRadius(
//         Rect.fromPoints(Offset(borderWidth.toDouble(), borderWidth.toDouble()),
//             Offset(parentWidth - borderWidth, parentHeight - borderWidth)),
//         Radius.circular((parentHeight + 1) / 2),
//       ),
//       backgroundPaint);

//   // if (hadGold) {
//   //   final ui.Rect rect = Rect.fromPoints(
//   //       Offset(0, 0),
//   //       Offset(goldWidth + textMargin * 2 + borderWidth + borderWidth,
//   //           parentHeight));

//   //   final Size rawImageSize = new Size(goldPropertyImage.width.toDouble(),
//   //       goldPropertyImage.height.toDouble());

//   //   FittedSizes outputImageSize = applyBoxFit(
//   //       BoxFit.fill, rawImageSize, Size(goldWidth, textSize + textMargin));

//   //   final Rect inputSubrect =
//   //       Alignment.topLeft.inscribe(outputImageSize.source, rect);

//   //   final Rect outputSubrect =
//   //       Alignment.center.inscribe(outputImageSize.destination, rect);

//   //   // canvas.drawImageRect(
//   //   //     goldPropertyImage, inputSubrect, outputSubrect, new Paint());

//   //   pricePainter.paint(
//   //     canvas,
//   //     Offset(goldWidth + textMargin * 2 - borderWidth, textMargin.toDouble()),
//   //   );
//   // } else {
//   pricePainter.paint(
//     canvas,
//     Offset(textMargin.toDouble(), textMargin.toDouble()),
//   );
//   // }

//   final triBorderPath = Path();
//   triBorderPath.moveTo(parentWidth / 2 - textMargin, parentHeight);
//   triBorderPath.lineTo(
//       parentWidth / 2, parentHeight + textMargin + borderWidth);
//   triBorderPath.lineTo(parentWidth / 2 + textMargin, parentHeight);
//   canvas.drawPath(triBorderPath, shadowPaint);

//   final triPaint = Paint()
//     ..color = backgroundPaint.color
//     ..style = PaintingStyle.fill;
//   final triPath = Path();
//   triPath.moveTo(parentWidth / 2 - textMargin + borderWidth,
//       parentHeight - borderWidth * 2);
//   triPath.lineTo(parentWidth / 2, parentHeight + textMargin - borderWidth);
//   triPath.lineTo(parentWidth / 2 + textMargin - borderWidth,
//       parentHeight - borderWidth * 2);
//   canvas.drawPath(triPath, triPaint);

//   final image = await pictureRecorder.endRecording().toImage(
//       parentWidth.toInt() + borderWidth * 2,
//       parentHeight.toInt() + textMargin + borderWidth);
//   final data = await image.toByteData(format: ui.ImageByteFormat.png);
//   return data!.buffer.asUint8List();
// }

// double convertRadiusToSigma(double radius) {
//   return radius * 0.57735 + 0.5;
// }

// Future<ui.Image> loadUiImage(List<int> img) async {
//   final Completer<ui.Image> completer = new Completer();
//   ui.decodeImageFromList(img, (ui.Image img) {
//     return completer.complete(img);
//   });
//   return completer.future;
// }

List<Map<String, Object>> mapStyle = [
  {
    "elementType": "labels",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "administrative.neighborhood",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "poi.business",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {"visibility": "off"}
    ]
  }
];

String mapstyleStr =
    '[{"elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},{"featureType":"administrative.neighborhood","stylers":[{"visibility":"off"}]},{"featureType":"poi","elementType":"labels.text","stylers":[{"visibility":"off"}]},{"featureType":"poi.business","stylers":[{"visibility":"off"}]},{"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]}]';
