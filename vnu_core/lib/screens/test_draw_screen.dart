import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';

class TestDrawScreen extends StatefulWidget {
  const TestDrawScreen({super.key});

  @override
  State<TestDrawScreen> createState() => _TestDrawScreenState();
}

class _TestDrawScreenState extends State<TestDrawScreen> {
  Image? image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Column(
          children: [
            Text('Image draw'),
            Visibility(visible: image != null, child: image ?? Container())
          ],
        ),
      ),
      floatingActionButton: IconButton(
          onPressed: () {
            //
            _drawCanvas();
          },
          icon: Icon(Icons.add)),
    );
  }

  _drawCanvas() async {
    log('draw');
    final pictureRecorder = PictureRecorder();

    final canvas = Canvas(pictureRecorder);

    _paintCircleFill(canvas, Colors.green);
    _paintCircleStroke(canvas, Colors.red);
    _paintIcon(canvas, Colors.white, Icons.map);

    final picture = pictureRecorder.endRecording();
    final imageObject = await picture.toImage(48, 48);

    final bytesObj = await imageObject.toByteData(format: ImageByteFormat.png);
    log('fnnish');
    setState(() {
      log(image.toString());
      image = Image.memory(bytesObj!.buffer.asUint8List());
    });
    // setState() {
    //   log(image.toString());
    //   image = Image.memory(bytesObj!.buffer.asUint8List());
    // }
  }

  /// Paints the icon background
  void _paintCircleFill(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(Offset(48 / 2, 48 / 2), 50, paint);
  }

  /// Paints a circle around the icon
  void _paintCircleStroke(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 48 / 10;
    canvas.drawCircle(Offset(48 / 2, 48 / 2), 45, paint);
  }

  /// Paints the icon
  void _paintIcon(Canvas canvas, Color color, IconData iconData) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          letterSpacing: 0.0,
          fontSize: 20,
          fontFamily: iconData.fontFamily,
          color: color,
        ));
    textPainter.layout();
    textPainter.paint(canvas, Offset(24, 24));
  }
}
