import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bubble kéo-thả trong phạm vi chính xác của Stack cha.
///
/// Widget tự cộng SafeArea và keyboard inset, hỗ trợ snap mượt sang cạnh gần
/// nhất, đồng thời báo vị trí mới để speech overlay tính lại placement.
class DraggableSpeechBubble extends StatefulWidget {
  const DraggableSpeechBubble({
    super.key,
    required this.child,
    required this.onTap,
    this.initialOffset,
    this.bubbleSize = const Size(64, 64),
    this.edgeInsets = const EdgeInsets.all(12),
    this.snapToHorizontalEdge = true,
    this.snapDuration = const Duration(milliseconds: 220),
    this.onPositionChanged,
  });

  final Widget child;
  final VoidCallback onTap;
  final Offset? initialOffset;
  final Size bubbleSize;
  final EdgeInsets edgeInsets;
  final bool snapToHorizontalEdge;
  final Duration snapDuration;
  final ValueChanged<Offset>? onPositionChanged;

  @override
  State<DraggableSpeechBubble> createState() =>
      _DraggableSpeechBubbleState();
}

class _DraggableSpeechBubbleState extends State<DraggableSpeechBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapController;

  Offset _position = Offset.zero;
  Offset _snapStart = Offset.zero;
  Offset _snapEnd = Offset.zero;
  Size _lastAvailableSize = Size.zero;
  bool _positionInitialized = false;

  @override
  void initState() {
    super.initState();

    _snapController = AnimationController(
      vsync: this,
      duration: widget.snapDuration,
    )..addListener(_onSnapTick);
  }

  @override
  void didUpdateWidget(covariant DraggableSpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.snapDuration != widget.snapDuration) {
      _snapController.duration = widget.snapDuration;
    }

    if (oldWidget.initialOffset != widget.initialOffset &&
        widget.initialOffset != null) {
      _position = widget.initialOffset!;
      _positionInitialized = true;
    }
  }

  EdgeInsets _effectiveInsets(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);

    return EdgeInsets.fromLTRB(
      widget.edgeInsets.left + media.padding.left,
      widget.edgeInsets.top + media.padding.top,
      widget.edgeInsets.right + media.padding.right,
      widget.edgeInsets.bottom +
          math.max(media.padding.bottom, media.viewInsets.bottom),
    );
  }

  Offset _defaultPosition(Size availableSize, EdgeInsets insets) {
    return Offset(
      math.max(
        insets.left,
        availableSize.width - widget.bubbleSize.width - insets.right,
      ),
      math.max(
        insets.top,
        availableSize.height - widget.bubbleSize.height - insets.bottom,
      ),
    );
  }

  Offset _clampOffset(
    Offset offset,
    Size availableSize,
    EdgeInsets insets,
  ) {
    final double minX = insets.left;
    final double minY = insets.top;
    final double maxX = math.max(
      minX,
      availableSize.width - widget.bubbleSize.width - insets.right,
    );
    final double maxY = math.max(
      minY,
      availableSize.height - widget.bubbleSize.height - insets.bottom,
    );

    return Offset(
      offset.dx.clamp(minX, maxX).toDouble(),
      offset.dy.clamp(minY, maxY).toDouble(),
    );
  }

  void _updatePosition(
    Offset value,
    Size availableSize,
    EdgeInsets insets, {
    bool rebuild = true,
  }) {
    final Offset next = _clampOffset(value, availableSize, insets);
    if (next == _position && _positionInitialized) return;

    if (rebuild && mounted) {
      setState(() {
        _position = next;
        _positionInitialized = true;
      });
    } else {
      _position = next;
      _positionInitialized = true;
    }

    widget.onPositionChanged?.call(next);
  }

  void _onSnapTick() {
    if (!mounted || _lastAvailableSize == Size.zero) return;

    final double value = Curves.easeOutCubic.transform(_snapController.value);
    final Offset next = Offset.lerp(_snapStart, _snapEnd, value)!;

    setState(() {
      _position = next;
    });
    widget.onPositionChanged?.call(next);
  }

  void _snapToNearestEdge(Size availableSize, EdgeInsets insets) {
    if (!widget.snapToHorizontalEdge) return;

    final double left = insets.left;
    final double right = math.max(
      left,
      availableSize.width - widget.bubbleSize.width - insets.right,
    );
    final double targetX =
        (_position.dx - left).abs() <= (_position.dx - right).abs()
            ? left
            : right;

    _snapController.stop();
    _snapStart = _position;
    _snapEnd = _clampOffset(
      Offset(targetX, _position.dy),
      availableSize,
      insets,
    );
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size availableSize = Size(
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width,
            constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height,
          );
          final EdgeInsets insets = _effectiveInsets(context);

          _lastAvailableSize = availableSize;

          if (!_positionInitialized) {
            _position = _clampOffset(
              widget.initialOffset ?? _defaultPosition(availableSize, insets),
              availableSize,
              insets,
            );
            _positionInitialized = true;
          } else {
            _position = _clampOffset(_position, availableSize, insets);
          }

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: _position.dx,
                top: _position.dy,
                width: widget.bubbleSize.width,
                height: widget.bubbleSize.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                  onPanStart: (_) => _snapController.stop(),
                  onPanUpdate: (DragUpdateDetails details) {
                    _updatePosition(
                      _position + details.delta,
                      availableSize,
                      insets,
                    );
                  },
                  onPanEnd: (_) => _snapToNearestEdge(availableSize, insets),
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: Colors.transparent,
                    child: widget.child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _snapController
      ..removeListener(_onSnapTick)
      ..dispose();
    super.dispose();
  }
}
