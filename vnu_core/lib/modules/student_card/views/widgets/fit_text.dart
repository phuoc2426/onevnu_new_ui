import 'package:flutter/material.dart';

class FitText extends StatelessWidget {
  const FitText(
      this.data, {
        super.key,
        this.style,
        this.maxLines = 1,
        required this.maxSize,
        required this.minSize,
        this.align = TextAlign.start,
      });

  final String data;
  final TextStyle? style;
  final int maxLines;
  final double maxSize, minSize;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      double best = minSize;
      for (double s = maxSize; s >= minSize; s -= 1) {
        final tp = TextPainter(
          text: TextSpan(text: data, style: (style ?? const TextStyle()).copyWith(fontSize: s)),
          textDirection: TextDirection.ltr,
          maxLines: maxLines,
        )..layout(maxWidth: c.maxWidth);
        if (!tp.didExceedMaxLines && tp.width <= c.maxWidth && tp.height <= c.maxHeight) {
          best = s; break;
        }
      }
      return Text(
        data,
        textAlign: align,
        style: (style ?? const TextStyle()).copyWith(fontSize: best),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    });
  }
}
