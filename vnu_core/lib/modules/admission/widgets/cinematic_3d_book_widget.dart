import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:page_flip/page_flip.dart';

// ═══════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════

class BookPage {
  final String title;
  final String content;

  const BookPage({
    required this.title,
    required this.content,
  });
}

// ═══════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════

const _kPageColor = Color(0xFFFFF6DA);
const _kPageText = Color(0xFF2C1A0E);
const _kPageBorder = Color(0xFF8B6914);
const _kGoldColor = Color(0xFFD4AF37);
const _kGoldLight = Color(0xFFF1D87A);
const _kAccentColor = Color(0xFFF840A8);
const _kPaperHighlight = Color(0xFFFFFDF0);

const double _kSpinePerspective = 0.002;
const double _kPerspective = 0.0016;

const double _kReadingLeft = 0.015;
const double _kReadingTop = 0.018;
const double _kReadingRight = 0.015;
const double _kReadingBottom = 0.018;

const double _kRevealStagger = 0.10;
const double _kRevealSlide = 18.0;

const double _kCoverWidthBase = 160.0;
const double _kBookHeightBase = 235.0;
const double _kSpineDepthBase = 42.0;

const double _kIdleTiltX = -0.11;
const double _kIdleTiltY = -0.03;
const double _kIdleRotateZ = -0.018;
const double _kIdleYaw = -0.30;
const double _kZoomScale = 0.56;

final double _kCoverMaxAngle = math.pi * 0.86;

double get kCoverWidth => _kCoverWidthBase;
double get kBookHeight => _kBookHeightBase;
double get kIdleYaw => _kIdleYaw;

// ═══════════════════════════════════════════════════════════════
// CinematicBook
// ═══════════════════════════════════════════════════════════════
// Flow mới:
// 1. Widget gốc lấy rect thật trên màn hình.
// 2. Tạo root overlay trong suốt.
// 3. Clone model sách vào overlay.
// 4. Model đi từ vị trí gốc ra giữa màn hình.
// 5. Khi đã ở giữa mới mở bìa.
// 6. Page block bung thành reading surface.
// ═══════════════════════════════════════════════════════════════

class CinematicBook extends StatefulWidget {
  final double scale;
  final String coverAsset;
  final String spineAsset;
  final List<BookPage> pages;
  final Duration openDuration;
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;

  const CinematicBook({
    super.key,
    this.scale = 0.30,
    required this.coverAsset,
    required this.spineAsset,
    required this.pages,
    this.openDuration = const Duration(milliseconds: 1900),
    this.onOpened,
    this.onClosed,
  });

  @override
  State<CinematicBook> createState() => CinematicBookState();
}

enum _Stage { idle, opening, reading, closing }

class CinematicBookState  extends State<CinematicBook>
    with TickerProviderStateMixin {
  late final AnimationController _bookCtrl;
  late final AnimationController _idleCtrl;

  late final Animation<double> _tapCompress;
  late final Animation<double> _moveToCenter;
  late final Animation<double> _cameraZoom;
  late final Animation<double> _tiltAnim;
  late final Animation<double> _coverOpen;
  late final Animation<double> _pageGlow;
  late final Animation<double> _surfaceAnim;
  late final Animation<double> _textReveal;
  late final Animation<double> _bookOpacity;

  _Stage _stage = _Stage.idle;

  final _bookWidgetKey = GlobalKey();
  final _pageBlockKey = GlobalKey();
  final _flipKey = GlobalKey<PageFlipWidgetState>();

  Rect? _bookOriginRect;
  Rect? _pageSourceRect;

  OverlayEntry? _overlay;

  double get _coverW => _kCoverWidthBase * widget.scale;
  double get _bookH => _kBookHeightBase * widget.scale;
  double get _spineD => _kSpineDepthBase * widget.scale;

  @override
  void initState() {
    super.initState();

    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _bookCtrl = AnimationController(
      vsync: this,
      duration: widget.openDuration,
    );

    // Tap feedback rất ngắn.
    _tapCompress = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.00,
        0.10,
        curve: Curves.easeOutCubic,
      ),
    );

    // Quan trọng: sách phải ra giữa trước.
    _moveToCenter = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.02,
        0.34,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Zoom camera chạy cùng đoạn sách bay ra giữa.
    _cameraZoom = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.04,
        0.34,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Model thẳng dần khi tới giữa màn hình.
    _tiltAnim = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.16,
        0.40,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Bìa chỉ mở sau khi model đã gần như ở giữa.
    _coverOpen = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.46,
        0.74,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );

    _pageGlow = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.58,
        0.78,
        curve: Curves.easeOutCubic,
      ),
    );

    // Paper surface bung ra cuối cùng.
    _surfaceAnim = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.76,
        1.00,
        curve: Curves.easeOutCubic,
      ),
    );

    _textReveal = CurvedAnimation(
      parent: _bookCtrl,
      curve: const Interval(
        0.84,
        1.00,
        curve: Curves.easeOutCubic,
      ),
    );

    _bookOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _bookCtrl,
        curve: const Interval(
          0.80,
          1.00,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _bookCtrl.addStatusListener(_onAnimStatus);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (!mounted) return;

    if (status == AnimationStatus.completed) {
      setState(() => _stage = _Stage.reading);
      _overlay?.markNeedsBuild();
      widget.onOpened?.call();
    }

    if (status == AnimationStatus.dismissed) {
      _cleanupOverlay();
      widget.onClosed?.call();
    }
  }

  void _cleanupOverlay() {
    _pageSourceRect = null;
    _bookOriginRect = null;

    if (mounted) {
      setState(() => _stage = _Stage.idle);
    }

    _overlay?.remove();
    _overlay = null;
    _idleCtrl.repeat();
  }

  @override
  void dispose() {
    _bookCtrl.removeStatusListener(_onAnimStatus);
    _bookCtrl.dispose();
    _idleCtrl.dispose();
    _overlay?.remove();
    super.dispose();
  }

  Rect? _globalRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;

    final ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;

    return ro.localToGlobal(Offset.zero) & ro.size;
  }
  void openBook() {
    _open();
  }
  void _open() {
    if (_stage != _Stage.idle) return;

    final origin = _globalRect(_bookWidgetKey);
    if (origin == null) return;

    _bookOriginRect = origin;
    _pageSourceRect = null;

    setState(() => _stage = _Stage.opening);
    _idleCtrl.stop();

    _overlay = OverlayEntry(
      builder: (_) => _OverlayScene(state: this),
    );

    // rootOverlay giúp widget dùng ở trang khác, nested route, dialog...
    // vẫn bay ra giữa toàn màn hình đúng vị trí.
    Overlay.of(context, rootOverlay: true).insert(_overlay!);

    // Đợi overlay render xong mới lấy rect thật của page block bên trong sách.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlay == null) return;

      _pageSourceRect = _globalRect(_pageBlockKey);
      _overlay?.markNeedsBuild();
      _bookCtrl.forward(from: 0);
    });
  }

  void _close() {
    if (_stage != _Stage.reading) return;

    _refreshBookOriginRect();

    setState(() => _stage = _Stage.closing);
    _overlay?.markNeedsBuild();

    _bookCtrl.animateBack(
      0,
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _refreshBookOriginRect() {
    final current = _globalRect(_bookWidgetKey);
    if (current != null) {
      _bookOriginRect = current;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _stage != _Stage.idle,
      child: AnimatedBuilder(
        animation: _idleCtrl,
        builder: (_, __) {
          final t = _idleCtrl.value * math.pi * 2;
          final floatY = math.sin(t) * 1.8;
          final shimmer = math.sin(t + math.pi / 3) * 0.5 + 0.5;
          final isIdle = _stage == _Stage.idle;

          return GestureDetector(
            key: _bookWidgetKey,
            onTap: _open,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: isIdle ? 1.0 : 0.0,
              child: Transform.translate(
                offset: Offset(0, isIdle ? floatY : 0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _kPerspective)
                    ..rotateX(_kIdleTiltX)
                    ..rotateY(_kIdleTiltY)
                    ..rotateZ(_kIdleRotateZ),
                  child: _BookModel(
                    coverW: _coverW,
                    bookH: _bookH,
                    spineD: _spineD,
                    yaw: _kIdleYaw,
                    coverAngle: 0,
                    pageReveal: 0,
                    shimmer: shimmer,
                    coverAsset: widget.coverAsset,
                    spineAsset: widget.spineAsset,
                    pageBlockKey: null,
                    hideInnerPage: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// OVERLAY SCENE
// Background transparent hoàn toàn. Không vignette, không dim layer.
// ═══════════════════════════════════════════════════════════════

class _OverlayScene extends StatelessWidget {
  final CinematicBookState  state;

  const _OverlayScene({required this.state});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([state._bookCtrl, state._idleCtrl]),
        builder: (ctx, _) {
          final s = state;

          final compress =
              1.0 - 0.04 * math.sin(s._tapCompress.value * math.pi);
          final zoom = 1.0 + s._cameraZoom.value * _kZoomScale;

          final tiltP = s._tiltAnim.value;
          final tiltX = lerpDouble(_kIdleTiltX, 0.0, tiltP)!;
          final tiltY = lerpDouble(_kIdleTiltY, 0.0, tiltP)!;
          final rotZ = lerpDouble(_kIdleRotateZ, 0.0, tiltP)!;
          final yaw = lerpDouble(_kIdleYaw, -0.09, tiltP)!;

          final coverAngle = s._coverOpen.value * _kCoverMaxAngle;
          final pageReveal = s._pageGlow.value;
          final bookAlpha = s._bookOpacity.value.clamp(0.0, 1.0);

          final surfaceP = Curves.easeOutCubic.transform(
            s._surfaceAnim.value.clamp(0.0, 1.0),
          );

          final screenSize = MediaQuery.of(ctx).size;
          final screenCenter = Offset(
            screenSize.width / 2,
            screenSize.height / 2,
          );

          final latestOriginRect = s._stage == _Stage.closing
              ? s._globalRect(s._bookWidgetKey) ?? s._bookOriginRect
              : s._bookOriginRect;

          final originCenter = latestOriginRect?.center ?? screenCenter;          final moveP = s._moveToCenter.value.clamp(0.0, 1.0);

          final bookCenter = Offset(
            lerpDouble(originCenter.dx, screenCenter.dx, moveP)!,
            lerpDouble(originCenter.dy, screenCenter.dy, moveP)!,
          );

          final targetPaperRect = Rect.fromLTWH(
            screenSize.width * _kReadingLeft,
            screenSize.height * _kReadingTop,
            screenSize.width * (1 - _kReadingLeft - _kReadingRight),
            screenSize.height * (1 - _kReadingTop - _kReadingBottom),
          );

          final sourcePaperRect = s._pageSourceRect;

          Rect? paperRect;
          if (sourcePaperRect != null && surfaceP > 0) {
            paperRect = Rect.fromLTWH(
              lerpDouble(sourcePaperRect.left, targetPaperRect.left, surfaceP)!,
              lerpDouble(sourcePaperRect.top, targetPaperRect.top, surfaceP)!,
              lerpDouble(
                sourcePaperRect.width,
                targetPaperRect.width,
                surfaceP,
              )!,
              lerpDouble(
                sourcePaperRect.height,
                targetPaperRect.height,
                surfaceP,
              )!,
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Lớp trong suốt để chặn tap xuyên xuống page bên dưới.
              // Không vẽ màu, nên background vẫn transparent.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: s._stage == _Stage.reading ? s._close : null,
                ),
              ),

              if (s._stage != _Stage.reading)
                Positioned(
                  left: bookCenter.dx,
                  top: bookCenter.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Opacity(
                      opacity: bookAlpha,
                      child: Transform.scale(
                        scale: compress * zoom,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, _kPerspective)
                            ..rotateX(tiltX)
                            ..rotateY(tiltY)
                            ..rotateZ(rotZ),
                          child: _BookModel(
                            coverW: s._coverW,
                            bookH: s._bookH,
                            spineD: s._spineD,
                            yaw: yaw,
                            coverAngle: coverAngle,
                            pageReveal: pageReveal,
                            shimmer: 0,
                            coverAsset: s.widget.coverAsset,
                            spineAsset: s.widget.spineAsset,
                            pageBlockKey: s._pageBlockKey,
                            hideInnerPage: surfaceP > 0.015,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              if (paperRect != null && surfaceP > 0)
                Positioned(
                  left: paperRect.left,
                  top: paperRect.top,
                  width: paperRect.width,
                  height: paperRect.height,
                  child: Opacity(
                    opacity: surfaceP.clamp(0.0, 1.0),
                    child: _PaperSurface(
                      child: (s._stage == _Stage.reading || s._stage == _Stage.closing)
                          ? IgnorePointer(
                        ignoring: s._stage == _Stage.closing,
                        child: _PageFlipArea(
                          flipKey: s._flipKey,
                          pages: s.widget.pages,
                        ),
                      )
                          : _SimplePageView(
                        page: s.widget.pages.isNotEmpty
                            ? s.widget.pages.first
                            : const BookPage(title: '', content: ''),
                        revealProgress: s._textReveal.value,
                      ),
                    ),
                  ),
                ),

              if (s._stage == _Stage.reading)
                Positioned(
                  top: 20,
                  right: 18,
                  child: _CloseBtn(onTap: s._close),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PUBLIC STATIC OBJECT PREVIEW
// ═══════════════════════════════════════════════════════════════

class CinematicBookObject extends StatelessWidget {
  final double coverWidth;
  final double bookHeight;
  final double yaw;
  final double coverAngle;
  final double pageReveal;
  final double shimmer;
  final String coverAsset;
  final String spineAsset;
  final GlobalKey pageBlockKey;
  final bool hideInnerPage;

  const CinematicBookObject({
    super.key,
    required this.coverWidth,
    required this.bookHeight,
    required this.yaw,
    required this.coverAngle,
    required this.pageReveal,
    required this.shimmer,
    required this.coverAsset,
    required this.spineAsset,
    required this.pageBlockKey,
    required this.hideInnerPage,
  });

  @override
  Widget build(BuildContext context) {
    final spineD = bookHeight * (_kSpineDepthBase / _kBookHeightBase);

    return _BookModel(
      coverW: coverWidth,
      bookH: bookHeight,
      spineD: spineD,
      yaw: yaw,
      coverAngle: coverAngle,
      pageReveal: pageReveal,
      shimmer: shimmer,
      coverAsset: coverAsset,
      spineAsset: spineAsset,
      pageBlockKey: pageBlockKey,
      hideInnerPage: hideInnerPage,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3D BOOK MODEL
// ═══════════════════════════════════════════════════════════════

class _BookModel extends StatelessWidget {
  final double coverW;
  final double bookH;
  final double spineD;
  final double yaw;
  final double coverAngle;
  final double pageReveal;
  final double shimmer;
  final String coverAsset;
  final String spineAsset;
  final GlobalKey? pageBlockKey;
  final bool hideInnerPage;

  const _BookModel({
    required this.coverW,
    required this.bookH,
    required this.spineD,
    required this.yaw,
    required this.coverAngle,
    required this.pageReveal,
    required this.shimmer,
    required this.coverAsset,
    required this.spineAsset,
    required this.pageBlockKey,
    required this.hideInnerPage,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0018)
        ..rotateY(yaw),
      child: SizedBox(
        width: coverW + spineD,
        height: bookH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: spineD,
              top: 0,
              child: SizedBox(
                width: coverW,
                height: bookH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _BackPlate(w: coverW, h: bookH),

                    if (!hideInnerPage && pageBlockKey != null)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: _PageBlock(
                          key: pageBlockKey,
                          w: coverW - 8,
                          h: bookH - 8,
                          reveal: pageReveal,
                        ),
                      ),

                    _FrontCover(
                      w: coverW,
                      h: bookH,
                      angle: coverAngle,
                      maxAngle: _kCoverMaxAngle,
                      asset: coverAsset,
                    ),

                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: 9,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.50),
                                Colors.black.withOpacity(0.16),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: spineD,
              top: 0,
              child: _Spine(
                w: spineD,
                h: bookH,
                asset: spineAsset,
                shimmer: shimmer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spine extends StatelessWidget {
  final double w;
  final double h;
  final double shimmer;
  final String asset;

  const _Spine({
    required this.w,
    required this.h,
    required this.asset,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, _kSpinePerspective)
        ..rotateY(math.pi / 2)
        ..translate(-w, 0.0, 0.0),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
                child: Image.asset(
                  asset,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => CustomPaint(
                    size: Size(w, h),
                    painter: _SpineFallback(),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.44),
                      Colors.transparent,
                      Colors.black.withOpacity(0.52),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _kGoldColor.withOpacity(0.50),
                    width: 0.8,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 10,
              bottom: 10,
              child: Container(
                width: 1.2,
                color: _kGoldColor.withOpacity(0.18 + shimmer * 0.20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrontCover extends StatelessWidget {
  final double w;
  final double h;
  final double angle;
  final double maxAngle;
  final String asset;

  const _FrontCover({
    required this.w,
    required this.h,
    required this.angle,
    required this.maxAngle,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0016)
        ..rotateY(angle),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
                child: Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CustomPaint(
                    size: Size(w, h),
                    painter: _CoverFallback(),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 2,
              bottom: 2,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 2,
              right: 2,
              top: 0,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 2,
              right: 2,
              bottom: 0,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (angle > 0.1)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(
                          (angle / maxAngle * 0.30).clamp(0.0, 0.30),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                  border: Border.all(
                    color: _kGoldColor.withOpacity(0.50),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBlock extends StatelessWidget {
  final double w;
  final double h;
  final double reveal;

  const _PageBlock({
    super.key,
    required this.w,
    required this.h,
    required this.reveal,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: reveal.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: lerpDouble(0.96, 1.0, reveal)!,
        alignment: Alignment.centerLeft,
        child: CustomPaint(
          size: Size(w, h),
          painter: _PageBlockPainter(),
        ),
      ),
    );
  }
}

class _PageBlockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFFCF2),
            Color(0xFFF9F1DA),
            Color(0xFFF1E4BF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, 15, s.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withOpacity(0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, 15, s.height)),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = _kGoldColor.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackPlate extends StatelessWidget {
  final double w;
  final double h;

  const _BackPlate({
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(3),
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A1520),
            Color(0xFF1E1018),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _kGoldColor.withOpacity(0.20),
          width: 0.6,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAPER SURFACE
// ═══════════════════════════════════════════════════════════════

class _PaperSurface extends StatelessWidget {
  final Widget child;

  const _PaperSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: _kGoldColor.withOpacity(0.06),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _PaperPainter(),
          child: child,
        ),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFFAE8),
            Color(0xFFF5E8C0),
            Color(0xFFE6D098),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.8,
          colors: [
            _kPaperHighlight.withOpacity(0.45),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    final stain = Paint()
      ..color = const Color(0xFF9C7A32).withOpacity(0.035);

    canvas.drawCircle(
      Offset(s.width * 0.20, s.height * 0.18),
      s.width * 0.09,
      stain,
    );

    canvas.drawCircle(
      Offset(s.width * 0.78, s.height * 0.80),
      s.width * 0.07,
      stain,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..color = _kPageBorder.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageFlipArea extends StatelessWidget {
  final GlobalKey<PageFlipWidgetState> flipKey;
  final List<BookPage> pages;

  const _PageFlipArea({
    required this.flipKey,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    return PageFlipWidget(
      key: flipKey,
      backgroundColor: _kPageColor,
      lastPage: Container(
        color: _kPageColor,
        child: const Center(
          child: Text(
            '✦  Hết  ✦',
            style: TextStyle(
              color: _kPageBorder,
              fontSize: 22,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
      children: [
        for (final p in pages)
          _SimplePageView(
            page: p,
            revealProgress: 1.0,
          ),
      ],
    );
  }
}

class _SimplePageView extends StatelessWidget {
  final BookPage page;
  final double revealProgress;

  const _SimplePageView({
    required this.page,
    required this.revealProgress,
  });

  @override
  Widget build(BuildContext context) {
    final rp = revealProgress;

    return Container(
      decoration: BoxDecoration(
        color: _kPageColor.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kPageBorder.withOpacity(0.30),
          width: 0.8,
        ),
      ),
      child: CustomPaint(
        painter: _FramePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _reveal(0, rp, const _GoldRule()),
              const SizedBox(height: 8),
              _reveal(
                1,
                rp,
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5C1A5C),
                    fontSize: 20,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Color(0x44F840A8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _reveal(2, rp, const _GoldRule()),
              const SizedBox(height: 14),
              Expanded(
                child: _reveal(
                  3,
                  rp,
                  SingleChildScrollView(
                    child: Text(
                      page.content,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        color: _kPageText,
                        fontSize: 13,
                        height: 1.70,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              _reveal(4, rp, const _GoldRule()),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _reveal(int index, double progress, Widget child) {
  if (progress >= 1.0) return child;

  final start = index * _kRevealStagger;
  final end = math.min(1.0, start + 0.35);

  final p = Interval(
    start,
    end,
    curve: Curves.easeOutCubic,
  ).transform(progress.clamp(0.0, 1.0));

  return Opacity(
    opacity: p.clamp(0.0, 1.0),
    child: Transform.translate(
      offset: Offset(0, (1 - p) * _kRevealSlide),
      child: child,
    ),
  );
}

class _CloseBtn extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '×',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 34,
            fontWeight: FontWeight.w300,
            fontFamily: 'serif',
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: _kPageBorder.withOpacity(0.40),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '✦',
            style: TextStyle(
              color: _kPageBorder,
              fontSize: 9,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: _kPageBorder.withOpacity(0.40),
          ),
        ),
      ],
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = _kPageBorder.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawRect(
      Rect.fromLTRB(7, 7, s.width - 7, s.height - 7),
      p,
    );

    final corners = [
      Offset(7, 7),
      Offset(s.width - 7, 7),
      Offset(7, s.height - 7),
      Offset(s.width - 7, s.height - 7),
    ];

    for (final c in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 3.5)
          ..lineTo(c.dx + 3.5, c.dy)
          ..lineTo(c.dx, c.dy + 3.5)
          ..lineTo(c.dx - 3.5, c.dy)
          ..close(),
        Paint()..color = _kPageBorder.withOpacity(0.40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// FALLBACK PAINTERS
// ═══════════════════════════════════════════════════════════════

class _SpineFallback extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF120512),
            Color(0xFF2A0A2A),
            Color(0xFF4A1B4A),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect),
    );

    final lp = Paint()
      ..color = _kGoldColor.withOpacity(0.60)
      ..strokeWidth = 0.8;

    for (final y in [12.0, s.height * 0.28, s.height * 0.72, s.height - 12]) {
      canvas.drawLine(
        Offset(4, y),
        Offset(s.width - 4, y),
        lp,
      );
    }

    final tp = TextPainter(
      text: const TextSpan(
        text: 'ARCANE',
        style: TextStyle(
          color: _kGoldLight,
          fontSize: 8,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(
      s.width / 2 - tp.height / 2,
      s.height / 2 + tp.width / 2,
    );
    canvas.rotate(-math.pi / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();

    canvas.drawRect(
      rect,
      Paint()
        ..color = _kGoldColor.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoverFallback extends CustomPainter {
  void _text(
      Canvas c,
      String t,
      double x,
      double y,
      double sz,
      Color col,
      bool bold,
      ) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: col,
          fontSize: sz,
          fontFamily: 'monospace',
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: bold ? 2.2 : 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(c, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF8B3580),
            Color(0xFF5B255C),
            Color(0xFF2A102A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    final b = Paint()
      ..color = _kGoldColor.withOpacity(0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRect(
      Rect.fromLTRB(8, 8, s.width - 8, s.height - 8),
      b,
    );

    canvas.drawRect(
      Rect.fromLTRB(14, 14, s.width - 14, s.height - 14),
      b..strokeWidth = 0.6,
    );

    final cx = s.width / 2;
    final cy = s.height * 0.22;

    canvas.drawCircle(
      Offset(cx, cy),
      30,
      Paint()
        ..color = _kGoldColor.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      7,
      Paint()..color = _kAccentColor.withOpacity(0.85),
    );

    canvas.drawRect(
      Rect.fromLTRB(18, s.height * 0.36, s.width - 18, s.height * 0.58),
      Paint()..color = Colors.black.withOpacity(0.28),
    );

    _text(canvas, 'ARCANE', cx, s.height * 0.42, 20, _kGoldLight, true);
    _text(canvas, 'CODEX', cx, s.height * 0.52, 16, _kGoldColor, true);
    _text(
      canvas,
      '✦ Book ✦',
      cx,
      s.height * 0.64,
      8,
      _kGoldColor.withOpacity(0.7),
      false,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = _kGoldColor.withOpacity(0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
