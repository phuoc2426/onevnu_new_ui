import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'your_space_screen.dart';

class ApplicantHomeScreen extends StatefulWidget {
  final String fullName;

  const ApplicantHomeScreen({
    super.key,
    required this.fullName,
  });

  @override
  State<ApplicantHomeScreen> createState() =>
      _ApplicantHomeScreenState();
}

class _ApplicantHomeScreenState
    extends State<ApplicantHomeScreen> {
  late VideoPlayerController
  _videoController;

  late ConfettiController
  _confettiController;

  final ScrollController
  _scrollController =
  ScrollController();

  final Map<int, bool>
  _sectionVisibility =
  <int, bool>{};

  final List<GlobalKey> _sectionKeys =
  List<GlobalKey>.generate(
    9,
        (_) => GlobalKey(),
  );

  bool _isVideoInitialized = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _initVideo();

    _scrollController.addListener(
      _onScroll,
    );

    _confettiController =
    ConfettiController(
      duration:
      const Duration(seconds: 5),
    )..play();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _onScroll();
    });
  }

  Future<void> _initVideo() async {
    _videoController =
        VideoPlayerController.asset(
          'assets/videos/logo_stream.mp4',
        );

    try {
      await _videoController.initialize();

      await _videoController
          .setLooping(true);

      await _videoController
          .setVolume(0);

      await _videoController.play();

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Không thể phát video Applicant Home: '
            '$error\n$stackTrace',
      );
    }
  }

  void _onScroll() {
    if (!mounted) return;

    for (
    int index = 0;
    index < _sectionKeys.length;
    index++
    ) {
      final GlobalKey key =
      _sectionKeys[index];

      final BuildContext? keyContext =
          key.currentContext;

      if (keyContext == null) continue;

      final RenderObject? renderObject =
      keyContext.findRenderObject();

      if (renderObject is! RenderBox) {
        continue;
      }

      final Offset position =
      renderObject.localToGlobal(
        Offset.zero,
      );

      final double screenHeight =
          MediaQuery.of(context)
              .size
              .height;

      final bool isVisible =
          position.dy <
              screenHeight - 100 &&
              position.dy +
                  renderObject
                      .size
                      .height >
                  0;

      if (isVisible &&
          _sectionVisibility[index] !=
              true) {
        setState(() {
          _sectionVisibility[index] =
          true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFF0D47A1),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildBackground(),
          Container(
            color:
            Colors.black.withOpacity(
              0.28,
            ),
          ),
          CustomScrollView(
            controller:
            _scrollController,
            physics:
            const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _buildHeroContent(),
              ),
              SliverPadding(
                padding:
                const EdgeInsets.only(
                  bottom: 120,
                ),
                sliver: SliverList(
                  delegate:
                  SliverChildListDelegate(
                    <Widget>[
                      Container(
                        key: _sectionKeys[0],
                        margin:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child:
                        const _ImageGallerySection(),
                      ),
                      _buildAnimatedSection(
                        index: 7,
                        child:
                        const _FooterSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment:
            Alignment.topCenter,
            child: ConfettiWidget(
              confettiController:
              _confettiController,
              blastDirectionality:
              BlastDirectionality
                  .explosive,
              shouldLoop: false,
              colors: const <Color>[
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child:
            _ExpandableFloatingButton(
              isExpanded: _isExpanded,
              onToggle: () {
                setState(() {
                  _isExpanded =
                  !_isExpanded;
                });
              },
              onNavigate: () async {
                debugPrint(
                  '[APPLICANT_HOME] Chuẩn bị mở YourSpaceScreen',
                );

                try {
                  await Get.to(
                        () => YourSpaceScreen(
                      fullName: widget.fullName,
                    ),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 250),
                  );

                  debugPrint(
                    '[APPLICANT_HOME] YourSpaceScreen đã đóng',
                  );
                } catch (error, stackTrace) {
                  debugPrint(
                    '[APPLICANT_HOME] '
                        'Lỗi mở YourSpaceScreen: $error',
                  );

                  debugPrintStack(
                    stackTrace: stackTrace,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (!_isVideoInitialized) {
      return Container(
        decoration:
        const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:
            Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF0A2E6B),
            ],
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController
            .value
            .size
            .width,
        height: _videoController
            .value
            .size
            .height,
        child:
        VideoPlayer(
          _videoController,
        ),
      ),
    );
  }

  Widget _buildHeroContent() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context)
            .padding
            .top +
            40,
        bottom: 60,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 32),
          Text(
            'Chúc mừng\n'
                '${widget.fullName}\n'
                'đã trúng tuyển vào\n'
                'Đại học Quốc gia Hà Nội!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight:
              FontWeight.bold,
              color: Colors.white,
              height: 1.4,
              shadows: <Shadow>[
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            'Khám phá VNU',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons
                .keyboard_double_arrow_down,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({
    required int index,
    required Widget child,
  }) {
    final bool visible =
        _sectionVisibility[index] ??
            false;

    return AnimatedOpacity(
      duration:
      const Duration(
        milliseconds: 600,
      ),
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration:
        const Duration(
          milliseconds: 600,
        ),
        offset: visible
            ? Offset.zero
            : const Offset(
          0,
          0.15,
        ),
        child: Container(
          key: _sectionKeys[index],
          margin:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ExpandableFloatingButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onNavigate;

  const _ExpandableFloatingButton({
    required this.isExpanded,
    required this.onToggle,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final double expandedWidth =
    (MediaQuery.of(context).size.width - 20)
        .clamp(0.0, 280.0)
        .toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: isExpanded ? expandedWidth : 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(29),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(29),
        clipBehavior: Clip.antiAlias,
        child: isExpanded
            ? Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  debugPrint(
                    '[APPLICANT_HOME] '
                        'Bấm Truy cập không gian',
                  );

                  onNavigate();
                },
                child: const SizedBox(
                  height: 58,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Truy cập không gian',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: Colors.white24,
            ),
            InkWell(
              onTap: onToggle,
              child: const SizedBox(
                width: 54,
                height: 58,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        )
            : InkWell(
          onTap: onToggle,
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.borderRadius = 20,
    this.blur = 22,
    this.opacity = 0.10,
    this.borderColor,
    this.padding =
    const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        borderRadius,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:
              Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(
                  opacity + 0.06,
                ),
                Colors.white.withOpacity(
                  opacity,
                ),
              ],
            ),
            borderRadius:
            BorderRadius.circular(
              borderRadius,
            ),
            border: Border.all(
              color: borderColor ??
                  Colors.white
                      .withOpacity(0.30),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FooterSection
    extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return const _GlassCard(
      opacity: 0.06,
      child: Column(
        children: <Widget>[
          Text(
            'ĐẠI HỌC QUỐC GIA HÀ NỘI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '144 Xuân Thủy, '
                'Cầu Giấy, Hà Nội',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
          Text(
            'Điện thoại: '
                '(024) 3754 7670',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
          Text(
            'Email: dhqghn@vnu.edu.vn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '© 2026 Bản quyền '
                'thuộc về ĐHQGHN',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageGallerySection
    extends StatelessWidget {
  const _ImageGallerySection();

  static const List<String> _images =
  <String>[
    'assets/images/p1_g.png',
    'assets/images/p3_g.png',
    'assets/images/p2_g.png',
    'assets/images/p4_g.png',
    'assets/images/p5_g.png',
    'assets/images/p6_g.png',
    'assets/images/p7_g.png',
    'assets/images/p8_g.png',
    'assets/images/p9_g.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _AnimatedGalleryImage(
          visibilityKey:
          'gallery_img_0',
          assetPath:
          'assets/images/p1_g.png',
          height: 200,
        ),
        const SizedBox(height: 8),
        const Row(
          children: <Widget>[
            Expanded(
              child:
              _AnimatedGalleryImage(
                visibilityKey:
                'gallery_img_1',
                assetPath:
                'assets/images/p3_g.png',
                height: 150,
                beginOffset:
                Offset(-0.15, 0),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child:
              _AnimatedGalleryImage(
                visibilityKey:
                'gallery_img_2',
                assetPath:
                'assets/images/p2_g.png',
                height: 150,
                beginOffset:
                Offset(0.15, 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (
        int index = 3;
        index < _images.length;
        index++
        ) ...<Widget>[
          _AnimatedGalleryImage(
            visibilityKey:
            'gallery_img_$index',
            assetPath:
            _images[index],
            height: 200,
          ),
          if (index !=
              _images.length - 1)
            const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AnimatedGalleryImage
    extends StatefulWidget {
  final String visibilityKey;
  final String assetPath;
  final double height;
  final Offset beginOffset;

  const _AnimatedGalleryImage({
    required this.visibilityKey,
    required this.assetPath,
    this.height = 200,
    this.beginOffset =
    const Offset(0, 0.15),
  });

  @override
  State<_AnimatedGalleryImage>
  createState() =>
      _AnimatedGalleryImageState();
}

class _AnimatedGalleryImageState
    extends State<
        _AnimatedGalleryImage>
    with
        SingleTickerProviderStateMixin {
  bool _isVisible = false;

  late final AnimationController
  _shineController;

  @override
  void initState() {
    super.initState();

    _shineController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(
            milliseconds: 1400,
          ),
        );
  }

  void _onVisibilityChanged(
      VisibilityInfo info,
      ) {
    if (_isVisible ||
        info.visibleFraction <= 0.1) {
      return;
    }

    setState(() {
      _isVisible = true;
    });

    Future<void>.delayed(
      const Duration(
        milliseconds: 550,
      ),
          () {
        if (!mounted) return;

        _shineController.forward(
          from: 0,
        );
      },
    );
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.visibilityKey),
      onVisibilityChanged:
      _onVisibilityChanged,
      child: AnimatedOpacity(
        duration:
        const Duration(
          milliseconds: 700,
        ),
        curve: Curves.easeOut,
        opacity:
        _isVisible ? 1 : 0,
        child: AnimatedSlide(
          duration:
          const Duration(
            milliseconds: 700,
          ),
          curve: Curves.easeOutCubic,
          offset: _isVisible
              ? Offset.zero
              : widget.beginOffset,
          child: AnimatedScale(
            duration:
            const Duration(
              milliseconds: 700,
            ),
            curve:
            Curves.easeOutCubic,
            scale:
            _isVisible ? 1 : 0.92,
            child: _buildGlassyImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassyImage() {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (
              BuildContext context,
              BoxConstraints constraints,
              ) {
            final double width =
                constraints.maxWidth;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 16,
                    sigmaY: 16,
                  ),
                  child: Container(
                    color: Colors.white
                        .withOpacity(
                      0.04,
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.90,
                  child: Image.asset(
                    widget.assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace?
                        stackTrace,
                        ) {
                      return Container(
                        color:
                        Colors.grey[800],
                        alignment:
                        Alignment.center,
                        child:
                        const Icon(
                          Icons.broken_image,
                          color:
                          Colors.white38,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius
                        .circular(
                      24,
                    ),
                    gradient:
                    LinearGradient(
                      begin: Alignment
                          .topLeft,
                      end: Alignment
                          .bottomRight,
                      colors: <Color>[
                        Colors.white
                            .withOpacity(
                          0.16,
                        ),
                        Colors.white
                            .withOpacity(
                          0.02,
                        ),
                        Colors.black
                            .withOpacity(
                          0.06,
                        ),
                      ],
                      stops:
                      const <double>[
                        0,
                        0.5,
                        1,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(
                        0.30,
                      ),
                      width: 1.2,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation:
                  _shineController,
                  builder: (
                      BuildContext context,
                      Widget? child,
                      ) {
                    final double progress =
                        _shineController
                            .value;

                    final double left =
                        -width * 0.6 +
                            width *
                                1.6 *
                                Curves
                                    .easeInOut
                                    .transform(
                                  progress,
                                );

                    return Positioned(
                      top: -40,
                      bottom: -40,
                      left: left,
                      width: width * 0.35,
                      child: Transform.rotate(
                        angle: -0.35,
                        child: Container(
                          decoration:
                          BoxDecoration(
                            gradient:
                            LinearGradient(
                              begin: Alignment
                                  .centerLeft,
                              end: Alignment
                                  .centerRight,
                              colors:
                              <Color>[
                                Colors.white
                                    .withOpacity(
                                  0,
                                ),
                                Colors.white
                                    .withOpacity(
                                  0.35,
                                ),
                                Colors.white
                                    .withOpacity(
                                  0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}