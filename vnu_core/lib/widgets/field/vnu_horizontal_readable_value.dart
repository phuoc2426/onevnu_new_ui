import 'package:flutter/material.dart';

/// Displays a single-line value without truncating its semantic content.
///
/// The visible line can be dragged horizontally when the value is wider than
/// its field. Trailing actions/icons must be placed outside this widget so they
/// remain fixed while only the text moves.
class VnuHorizontalReadableValue extends StatelessWidget {
  const VnuHorizontalReadableValue({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.physics = const ClampingScrollPhysics(),
    this.centerWhenFits = false,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final ScrollPhysics physics;
  final bool centerWhenFits;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Text(
              text,
              maxLines: 1,
              softWrap: false,
              textAlign: textAlign,
              overflow: TextOverflow.visible,
              style: style,
            );

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: physics,
              child: centerWhenFits && constraints.hasBoundedWidth
                  ? ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: content,
                    )
                  : content,
            );
          },
        ),
      ),
    );
  }
}
