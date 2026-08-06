import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SpeechBubblePlacement {
  auto,
  top,
  bottom,
  left,
  right,
}

class SpeechBubbleController {
  _SpeechBubbleAnchorState? _anchorState;
  OverlayEntry? _overlayEntry;
  GlobalKey<_SpeechBubbleOverlayState>? _overlayKey;

  bool get isShowing => _overlayEntry != null;

  void _attachAnchor(_SpeechBubbleAnchorState state) {
    _anchorState = state;
  }

  void _detachAnchor(_SpeechBubbleAnchorState state) {
    if (identical(_anchorState, state)) {
      _anchorState = null;
      _removeImmediately();
    }
  }

  Future<void> show({
    required String text,
    SpeechBubblePlacement preferredPlacement = SpeechBubblePlacement.auto,
    Duration animationDuration = const Duration(milliseconds: 240),
    Duration? autoHideAfter,
    double maxWidth = 320,
    double maxHeightFactor = 0.55,
    double gap = 8,
    double screenMargin = 12,
    Color backgroundColor = const Color(0xFF25282E),
    Color? borderColor,
    TextStyle textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.4,
    ),
    EdgeInsets contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    bool dismissOnTapOutside = true,
    VoidCallback? onTap,
    bool Function()? canShow,
  }) async {
    final String normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    assert(maxWidth > 0);
    assert(maxHeightFactor > 0 && maxHeightFactor <= 1);

    await hide();

    if (canShow != null && !canShow()) {
      return;
    }

    final _SpeechBubbleAnchorState? anchorState = _anchorState;
    if (anchorState == null || !anchorState.mounted) {
      return;
    }

    final OverlayState overlayState = Overlay.of(
      anchorState.context,
      rootOverlay: true,
    );
    final GlobalKey<_SpeechBubbleOverlayState> overlayKey =
        GlobalKey<_SpeechBubbleOverlayState>();

    late final OverlayEntry entry;

    void removeEntry() {
      if (entry.mounted) {
        entry.remove();
      }

      if (identical(_overlayEntry, entry)) {
        _overlayEntry = null;
        _overlayKey = null;
      }
    }

    entry = OverlayEntry(
      builder: (BuildContext context) {
        return _SpeechBubbleOverlay(
          key: overlayKey,
          link: anchorState.layerLink,
          anchorContext: anchorState.context,
          text: normalizedText,
          preferredPlacement: preferredPlacement,
          animationDuration: animationDuration,
          autoHideAfter: autoHideAfter,
          maxWidth: maxWidth,
          maxHeightFactor: maxHeightFactor,
          gap: gap,
          screenMargin: screenMargin,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          textStyle: textStyle,
          contentPadding: contentPadding,
          dismissOnTapOutside: dismissOnTapOutside,
          onTap: onTap,
          onRemove: removeEntry,
        );
      },
    );

    _overlayEntry = entry;
    _overlayKey = overlayKey;
    overlayState.insert(entry);
  }

  Future<void> hide() async {
    final OverlayEntry? entry = _overlayEntry;
    if (entry == null) return;

    final _SpeechBubbleOverlayState? overlayState = _overlayKey?.currentState;
    if (overlayState != null) {
      await overlayState.dismiss();
    } else {
      _removeImmediately();
    }
  }

  /// Tính lại placement sau khi anchor di chuyển hoặc layout thay đổi.
  void refresh() {
    _overlayKey?.currentState?.recalculate();
  }

  void _removeImmediately() {
    final OverlayEntry? entry = _overlayEntry;
    _overlayEntry = null;
    _overlayKey = null;

    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  void dispose() {
    _removeImmediately();
    _anchorState = null;
  }
}

class SpeechBubbleAnchor extends StatefulWidget {
  const SpeechBubbleAnchor({
    super.key,
    required this.controller,
    required this.child,
  });

  final SpeechBubbleController controller;
  final Widget child;

  @override
  State<SpeechBubbleAnchor> createState() => _SpeechBubbleAnchorState();
}

class _SpeechBubbleAnchorState extends State<SpeechBubbleAnchor> {
  final LayerLink layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.controller._attachAnchor(this);
  }

  @override
  void didUpdateWidget(covariant SpeechBubbleAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detachAnchor(this);
      widget.controller._attachAnchor(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detachAnchor(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: widget.child,
    );
  }
}

class _SpeechBubbleOverlay extends StatefulWidget {
  const _SpeechBubbleOverlay({
    super.key,
    required this.link,
    required this.anchorContext,
    required this.text,
    required this.preferredPlacement,
    required this.animationDuration,
    required this.autoHideAfter,
    required this.maxWidth,
    required this.maxHeightFactor,
    required this.gap,
    required this.screenMargin,
    required this.backgroundColor,
    required this.borderColor,
    required this.textStyle,
    required this.contentPadding,
    required this.dismissOnTapOutside,
    required this.onTap,
    required this.onRemove,
  });

  final LayerLink link;
  final BuildContext anchorContext;
  final String text;
  final SpeechBubblePlacement preferredPlacement;
  final Duration animationDuration;
  final Duration? autoHideAfter;
  final double maxWidth;
  final double maxHeightFactor;
  final double gap;
  final double screenMargin;
  final Color backgroundColor;
  final Color? borderColor;
  final TextStyle textStyle;
  final EdgeInsets contentPadding;
  final bool dismissOnTapOutside;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  @override
  State<_SpeechBubbleOverlay> createState() =>
      _SpeechBubbleOverlayState();
}

class _SpeechBubbleOverlayState extends State<_SpeechBubbleOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _arrowHeight = 10;
  static const double _arrowWidth = 18;
  static const double _borderRadius = 14;

  final GlobalKey _measureKey = GlobalKey();

  late final AnimationController _animationController;

  _BubbleGeometry? _geometry;
  Size? _measuredBodySize;
  Timer? _autoHideTimer;
  bool _isReady = false;
  bool _isRemoving = false;
  bool _recalculateScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      reverseDuration: const Duration(milliseconds: 170),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndPlace());
  }

  @override
  void didChangeMetrics() {
    recalculate();
  }

  void recalculate() {
    if (!mounted || _recalculateScheduled || _isRemoving) return;

    _recalculateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateScheduled = false;
      if (!mounted || _isRemoving) return;
      _measureAndPlace();
    });
  }

  Widget _buildBody({Key? key}) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double availableWidth = math.max(
      1.0,
      mediaQuery.size.width -
          mediaQuery.padding.horizontal -
          widget.screenMargin * 2 -
          _arrowHeight,
    );
    final double availableHeight = math.max(
      1.0,
      mediaQuery.size.height -
          mediaQuery.padding.vertical -
          mediaQuery.viewInsets.bottom -
          widget.screenMargin * 2 -
          _arrowHeight,
    );

    final double bodyMaxWidth = math.min(widget.maxWidth, availableWidth);
    final double bodyMaxHeight = math.min(
      availableHeight,
      mediaQuery.size.height * widget.maxHeightFactor,
    );

    return RepaintBoundary(
      key: key,
      child: _BubbleBody(
        text: widget.text,
        textStyle: widget.textStyle,
        padding: widget.contentPadding,
        maxWidth: bodyMaxWidth,
        maxHeight: bodyMaxHeight,
      ),
    );
  }

  void _measureAndPlace() {
    if (!mounted || _isRemoving) return;

    final RenderObject? measurementObject =
        _measureKey.currentContext?.findRenderObject();
    final RenderObject? anchorObject = widget.anchorContext.findRenderObject();
    final RenderObject? overlayObject = Overlay.of(
      context,
      rootOverlay: true,
    ).context.findRenderObject();

    if (anchorObject is! RenderBox ||
        overlayObject is! RenderBox ||
        !anchorObject.hasSize ||
        !overlayObject.hasSize ||
        !anchorObject.attached) {
      recalculate();
      return;
    }

    Size? bodySize = _measuredBodySize;
    if (measurementObject is RenderBox && measurementObject.hasSize) {
      bodySize = measurementObject.size;
      _measuredBodySize = bodySize;
    }

    if (bodySize == null) {
      recalculate();
      return;
    }
    final Offset anchorGlobal = anchorObject.localToGlobal(Offset.zero);
    final Offset anchorInOverlay = overlayObject.globalToLocal(anchorGlobal);
    final Rect anchorRect = anchorInOverlay & anchorObject.size;

    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Size overlaySize = overlayObject.size;
    final double bottomInset = math.max(
      mediaQuery.padding.bottom,
      mediaQuery.viewInsets.bottom,
    );

    final Rect viewport = Rect.fromLTRB(
      mediaQuery.padding.left + widget.screenMargin,
      mediaQuery.padding.top + widget.screenMargin,
      overlaySize.width - mediaQuery.padding.right - widget.screenMargin,
      overlaySize.height - bottomInset - widget.screenMargin,
    );

    final SpeechBubblePlacement placement = _selectPlacement(
      anchorRect: anchorRect,
      viewport: viewport,
      bodySize: bodySize,
    );
    final Size bubbleSize = _calculateBubbleSize(bodySize, placement);
    final _BubbleGeometry geometry = _calculateGeometry(
      anchorRect: anchorRect,
      viewport: viewport,
      bubbleSize: bubbleSize,
      placement: placement,
    );

    setState(() {
      _geometry = geometry;
      _isReady = true;
    });

    if (_animationController.status == AnimationStatus.dismissed) {
      _animationController.forward().then((_) {
        if (!mounted || widget.autoHideAfter == null || _isRemoving) return;

        _autoHideTimer?.cancel();
        _autoHideTimer = Timer(widget.autoHideAfter!, dismiss);
      });
    }
  }

  SpeechBubblePlacement _selectPlacement({
    required Rect anchorRect,
    required Rect viewport,
    required Size bodySize,
  }) {
    final Map<SpeechBubblePlacement, Size> bubbleSizes =
        <SpeechBubblePlacement, Size>{
      SpeechBubblePlacement.top:
          _calculateBubbleSize(bodySize, SpeechBubblePlacement.top),
      SpeechBubblePlacement.bottom:
          _calculateBubbleSize(bodySize, SpeechBubblePlacement.bottom),
      SpeechBubblePlacement.left:
          _calculateBubbleSize(bodySize, SpeechBubblePlacement.left),
      SpeechBubblePlacement.right:
          _calculateBubbleSize(bodySize, SpeechBubblePlacement.right),
    };

    final Map<SpeechBubblePlacement, double> available =
        <SpeechBubblePlacement, double>{
      SpeechBubblePlacement.top:
          anchorRect.top - viewport.top - widget.gap,
      SpeechBubblePlacement.bottom:
          viewport.bottom - anchorRect.bottom - widget.gap,
      SpeechBubblePlacement.left:
          anchorRect.left - viewport.left - widget.gap,
      SpeechBubblePlacement.right:
          viewport.right - anchorRect.right - widget.gap,
    };

    final List<SpeechBubblePlacement> defaults = <SpeechBubblePlacement>[
      SpeechBubblePlacement.top,
      SpeechBubblePlacement.left,
      SpeechBubblePlacement.bottom,
      SpeechBubblePlacement.right,
    ];

    final List<SpeechBubblePlacement> order;
    if (widget.preferredPlacement == SpeechBubblePlacement.auto) {
      order = defaults;
    } else {
      order = <SpeechBubblePlacement>[
        widget.preferredPlacement,
        ...defaults.where(
          (SpeechBubblePlacement item) =>
              item != widget.preferredPlacement,
        ),
      ];
    }

    for (final SpeechBubblePlacement placement in order) {
      final Size size = bubbleSizes[placement]!;
      final double requiredSpace =
          placement == SpeechBubblePlacement.top ||
                  placement == SpeechBubblePlacement.bottom
              ? size.height
              : size.width;

      if (available[placement]! >= requiredSpace) {
        return placement;
      }
    }

    SpeechBubblePlacement best = order.first;
    double bestScore = double.negativeInfinity;

    for (final SpeechBubblePlacement placement in order) {
      final Size size = bubbleSizes[placement]!;
      final double requiredSpace =
          placement == SpeechBubblePlacement.top ||
                  placement == SpeechBubblePlacement.bottom
              ? size.height
              : size.width;
      final double score = available[placement]! / math.max(requiredSpace, 1.0);

      if (score > bestScore) {
        bestScore = score;
        best = placement;
      }
    }

    return best;
  }

  Size _calculateBubbleSize(
    Size bodySize,
    SpeechBubblePlacement placement,
  ) {
    switch (placement) {
      case SpeechBubblePlacement.top:
      case SpeechBubblePlacement.bottom:
        return Size(bodySize.width, bodySize.height + _arrowHeight);
      case SpeechBubblePlacement.left:
      case SpeechBubblePlacement.right:
        return Size(bodySize.width + _arrowHeight, bodySize.height);
      case SpeechBubblePlacement.auto:
        return bodySize;
    }
  }

  _BubbleGeometry _calculateGeometry({
    required Rect anchorRect,
    required Rect viewport,
    required Size bubbleSize,
    required SpeechBubblePlacement placement,
  }) {
    late Alignment targetAnchor;
    late Alignment followerAnchor;
    late Offset baseTopLeft;
    late Offset desiredTopLeft;

    switch (placement) {
      case SpeechBubblePlacement.top:
        targetAnchor = Alignment.topCenter;
        followerAnchor = Alignment.bottomCenter;
        baseTopLeft = Offset(
          anchorRect.center.dx - bubbleSize.width / 2,
          anchorRect.top - bubbleSize.height,
        );
        desiredTopLeft = Offset(
          baseTopLeft.dx,
          anchorRect.top - widget.gap - bubbleSize.height,
        );
        break;
      case SpeechBubblePlacement.bottom:
        targetAnchor = Alignment.bottomCenter;
        followerAnchor = Alignment.topCenter;
        baseTopLeft = Offset(
          anchorRect.center.dx - bubbleSize.width / 2,
          anchorRect.bottom,
        );
        desiredTopLeft = Offset(
          baseTopLeft.dx,
          anchorRect.bottom + widget.gap,
        );
        break;
      case SpeechBubblePlacement.left:
        targetAnchor = Alignment.centerLeft;
        followerAnchor = Alignment.centerRight;
        baseTopLeft = Offset(
          anchorRect.left - bubbleSize.width,
          anchorRect.center.dy - bubbleSize.height / 2,
        );
        desiredTopLeft = Offset(
          anchorRect.left - widget.gap - bubbleSize.width,
          baseTopLeft.dy,
        );
        break;
      case SpeechBubblePlacement.right:
        targetAnchor = Alignment.centerRight;
        followerAnchor = Alignment.centerLeft;
        baseTopLeft = Offset(
          anchorRect.right,
          anchorRect.center.dy - bubbleSize.height / 2,
        );
        desiredTopLeft = Offset(
          anchorRect.right + widget.gap,
          baseTopLeft.dy,
        );
        break;
      case SpeechBubblePlacement.auto:
        throw StateError('Placement auto must be resolved first.');
    }

    final Offset topLeft = Offset(
      _clamp(
        desiredTopLeft.dx,
        viewport.left,
        viewport.right - bubbleSize.width,
      ),
      _clamp(
        desiredTopLeft.dy,
        viewport.top,
        viewport.bottom - bubbleSize.height,
      ),
    );
    final Offset followerOffset = topLeft - baseTopLeft;

    late double arrowOffset;
    if (placement == SpeechBubblePlacement.top ||
        placement == SpeechBubblePlacement.bottom) {
      final double safeEdge = math.min(
        _borderRadius + _arrowWidth / 2,
        bubbleSize.width / 2,
      );
      arrowOffset = _clamp(
        anchorRect.center.dx - topLeft.dx,
        safeEdge,
        bubbleSize.width - safeEdge,
      );
    } else {
      final double safeEdge = math.min(
        _borderRadius + _arrowWidth / 2,
        bubbleSize.height / 2,
      );
      arrowOffset = _clamp(
        anchorRect.center.dy - topLeft.dy,
        safeEdge,
        bubbleSize.height - safeEdge,
      );
    }

    return _BubbleGeometry(
      placement: placement,
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      followerOffset: followerOffset,
      arrowOffset: arrowOffset,
    );
  }

  double _clamp(double value, double minimum, double maximum) {
    if (maximum < minimum) return minimum;
    return value.clamp(minimum, maximum).toDouble();
  }

  Offset _slideBegin(SpeechBubblePlacement placement) {
    switch (placement) {
      case SpeechBubblePlacement.top:
        return const Offset(0, 0.08);
      case SpeechBubblePlacement.bottom:
        return const Offset(0, -0.08);
      case SpeechBubblePlacement.left:
        return const Offset(0.08, 0);
      case SpeechBubblePlacement.right:
        return const Offset(-0.08, 0);
      case SpeechBubblePlacement.auto:
        return Offset.zero;
    }
  }

  Alignment _scaleAlignment(SpeechBubblePlacement placement) {
    switch (placement) {
      case SpeechBubblePlacement.top:
        return Alignment.bottomCenter;
      case SpeechBubblePlacement.bottom:
        return Alignment.topCenter;
      case SpeechBubblePlacement.left:
        return Alignment.centerRight;
      case SpeechBubblePlacement.right:
        return Alignment.centerLeft;
      case SpeechBubblePlacement.auto:
        return Alignment.center;
    }
  }

  Future<void> dismiss() async {
    if (_isRemoving) return;

    _isRemoving = true;
    _autoHideTimer?.cancel();

    if (_animationController.value > 0) {
      await _animationController.reverse();
    }

    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _geometry == null) {
      return Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: _buildBody(key: _measureKey),
              ),
            ),
          ),
        ],
      );
    }

    final _BubbleGeometry geometry = _geometry!;
    final Animation<double> curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final Animation<double> scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(curvedAnimation);
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: _slideBegin(geometry.placement),
      end: Offset.zero,
    ).animate(curvedAnimation);

    final Widget bubble = _BubbleSurface(
      placement: geometry.placement,
      arrowOffset: geometry.arrowOffset,
      arrowHeight: _arrowHeight,
      arrowWidth: _arrowWidth,
      borderRadius: _borderRadius,
      backgroundColor: widget.backgroundColor,
      borderColor: widget.borderColor,
      child: _buildBody(),
    );

    return Stack(
      children: <Widget>[
        if (widget.dismissOnTapOutside)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: dismiss,
              child: const SizedBox.expand(),
            ),
          ),
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          targetAnchor: geometry.targetAnchor,
          followerAnchor: geometry.followerAnchor,
          offset: geometry.followerOffset,
          child: FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: ScaleTransition(
                alignment: _scaleAlignment(geometry.placement),
                scale: scaleAnimation,
                child: Material(
                  type: MaterialType.transparency,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onTap,
                    child: bubble,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoHideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.text,
    required this.textStyle,
    required this.padding,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String text;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: padding,
        child: Text(text, style: textStyle),
      ),
    );
  }
}

class _BubbleSurface extends StatelessWidget {
  const _BubbleSurface({
    required this.placement,
    required this.arrowOffset,
    required this.arrowHeight,
    required this.arrowWidth,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  final SpeechBubblePlacement placement;
  final double arrowOffset;
  final double arrowHeight;
  final double arrowWidth;
  final double borderRadius;
  final Color backgroundColor;
  final Color? borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    EdgeInsets arrowPadding = EdgeInsets.zero;

    switch (placement) {
      case SpeechBubblePlacement.top:
        arrowPadding = EdgeInsets.only(bottom: arrowHeight);
        break;
      case SpeechBubblePlacement.bottom:
        arrowPadding = EdgeInsets.only(top: arrowHeight);
        break;
      case SpeechBubblePlacement.left:
        arrowPadding = EdgeInsets.only(right: arrowHeight);
        break;
      case SpeechBubblePlacement.right:
        arrowPadding = EdgeInsets.only(left: arrowHeight);
        break;
      case SpeechBubblePlacement.auto:
        break;
    }

    return CustomPaint(
      painter: _SpeechBubblePainter(
        placement: placement,
        arrowOffset: arrowOffset,
        arrowHeight: arrowHeight,
        arrowWidth: arrowWidth,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
      ),
      child: Padding(
        padding: arrowPadding,
        child: child,
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter({
    required this.placement,
    required this.arrowOffset,
    required this.arrowHeight,
    required this.arrowWidth,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
  });

  final SpeechBubblePlacement placement;
  final double arrowOffset;
  final double arrowHeight;
  final double arrowWidth;
  final double borderRadius;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    late Rect bodyRect;

    switch (placement) {
      case SpeechBubblePlacement.top:
        bodyRect = Rect.fromLTRB(0, 0, size.width, size.height - arrowHeight);
        break;
      case SpeechBubblePlacement.bottom:
        bodyRect = Rect.fromLTRB(0, arrowHeight, size.width, size.height);
        break;
      case SpeechBubblePlacement.left:
        bodyRect = Rect.fromLTRB(0, 0, size.width - arrowHeight, size.height);
        break;
      case SpeechBubblePlacement.right:
        bodyRect = Rect.fromLTRB(arrowHeight, 0, size.width, size.height);
        break;
      case SpeechBubblePlacement.auto:
        bodyRect = Offset.zero & size;
        break;
    }

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(borderRadius)),
      );
    final Path arrowPath = Path();

    switch (placement) {
      case SpeechBubblePlacement.top:
        arrowPath
          ..moveTo(arrowOffset - arrowWidth / 2, bodyRect.bottom)
          ..lineTo(arrowOffset + arrowWidth / 2, bodyRect.bottom)
          ..lineTo(arrowOffset, size.height)
          ..close();
        break;
      case SpeechBubblePlacement.bottom:
        arrowPath
          ..moveTo(arrowOffset - arrowWidth / 2, bodyRect.top)
          ..lineTo(arrowOffset + arrowWidth / 2, bodyRect.top)
          ..lineTo(arrowOffset, 0)
          ..close();
        break;
      case SpeechBubblePlacement.left:
        arrowPath
          ..moveTo(bodyRect.right, arrowOffset - arrowWidth / 2)
          ..lineTo(bodyRect.right, arrowOffset + arrowWidth / 2)
          ..lineTo(size.width, arrowOffset)
          ..close();
        break;
      case SpeechBubblePlacement.right:
        arrowPath
          ..moveTo(bodyRect.left, arrowOffset - arrowWidth / 2)
          ..lineTo(bodyRect.left, arrowOffset + arrowWidth / 2)
          ..lineTo(0, arrowOffset)
          ..close();
        break;
      case SpeechBubblePlacement.auto:
        break;
    }

    path.addPath(arrowPath, Offset.zero);

    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.22),
      10,
      true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );

    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.placement != placement ||
        oldDelegate.arrowOffset != arrowOffset ||
        oldDelegate.arrowHeight != arrowHeight ||
        oldDelegate.arrowWidth != arrowWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor;
  }
}

class _BubbleGeometry {
  const _BubbleGeometry({
    required this.placement,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.followerOffset,
    required this.arrowOffset,
  });

  final SpeechBubblePlacement placement;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset followerOffset;
  final double arrowOffset;
}
