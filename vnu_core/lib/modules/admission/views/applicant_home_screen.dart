import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:confetti/confetti.dart'; // Confetti effect
import 'package:visibility_detector/visibility_detector.dart'; // 👈 THÊM package này vào pubspec.yaml
import 'your_space_screen.dart'; // 👈 Đường dẫn tới YourSpaceScreen

class ApplicantHomeScreen extends StatefulWidget {
  final String fullName;
  const ApplicantHomeScreen({Key? key, required this.fullName})
    : super(key: key);

  @override
  State<ApplicantHomeScreen> createState() => _ApplicantHomeScreenState();
}

class _ApplicantHomeScreenState extends State<ApplicantHomeScreen>
    with SingleTickerProviderStateMixin {
  // Video Player
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // Scroll & Animation
  final ScrollController _scrollController = ScrollController();
  final Map<int, bool> _sectionVisibility = {};
  // Increase to 9 to accommodate the new image gallery section at index 0
  final List<GlobalKey> _sectionKeys = List.generate(9, (_) => GlobalKey());

  // Nút nổi
  bool _isNearBottom = false;
  bool _isExpanded = false;
  // Confetti controller for celebratory effect
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _scrollController.addListener(_onScroll);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    )..play();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _initVideo() {
    _videoController =
        VideoPlayerController.asset('assets/videos/logo_stream.mp4')
          ..initialize()
              .then((_) {
                _videoController.setLooping(true);
                _videoController.setVolume(0.0);
                _videoController.play();
                setState(() {
                  _isVideoInitialized = true;
                });
              })
              .catchError((error) {
                print("❌ Lỗi khởi tạo video asset: $error");
              });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final nearBottom = (maxScroll - currentScroll) <= 100;
      if (nearBottom != _isNearBottom) {
        setState(() {
          _isNearBottom = nearBottom;
        });
      }
    }

    for (int i = 0; i < _sectionKeys.length; i++) {
      final key = _sectionKeys[i];
      if (key.currentContext != null) {
        final box = key.currentContext!.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(
            Offset.zero,
            ancestor: context.findRenderObject(),
          );
          final screenHeight = MediaQuery.of(context).size.height;
          final isVisible =
              position.dy < screenHeight - 100 &&
              position.dy + box.size.height > 0;
          if (isVisible && _sectionVisibility[i] != true) {
            setState(() {
              _sectionVisibility[i] = true;
            });
          }
        }
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

  bool get _showFloatingButton => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Background
          _isVideoInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                )
              // 👇 Nếu video chưa/không init, dùng gradient thay vì màu phẳng
              // để lớp kính (blur) phía trên vẫn có gì đó để "bẻ" ánh sáng,
              // nếu không thì blur trên nền phẳng sẽ luôn nhìn như "đục".
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D47A1),
                        Color(0xFF1565C0),
                        Color(0xFF0A2E6B),
                      ],
                    ),
                  ),
                ),

          // Overlay tối - giảm opacity để card kính lộ rõ độ trong suốt hơn
          Container(color: Colors.black.withOpacity(0.28)),

          // Nội dung cuộn
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeroContent()),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 👇 KHÔNG bọc gallery trong _buildAnimatedSection nữa,
                    // vì bản thân gallery giờ tự animate từng ảnh riêng lẻ.
                    Container(
                      key: _sectionKeys[0],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const _ImageGallerySection(),
                    ),

                    _buildAnimatedSection(
                      index: 7,
                      child: const _FooterSection(),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          // Confetti overlay (celebration effect)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          if (_showFloatingButton)
            Positioned(
              bottom: 10,
              right: 10,
              child: _ExpandableFloatingButton(
                isExpanded: _isExpanded,
                onToggle: () => setState(() => _isExpanded = !_isExpanded),
                onNavigate: () =>
                    Get.to(() => YourSpaceScreen(fullName: widget.fullName)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroContent() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40,
        bottom: 60,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            'Chúc mừng\n${widget.fullName}\nđã trúng tuyển vào\nĐại học Quốc gia \nHà Nội!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
              shadows: [
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
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.keyboard_double_arrow_down,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    final visible = _sectionVisibility[index] ?? false;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: visible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 600),
        offset: visible ? Offset.zero : const Offset(0, 0.15),
        child: Container(
          key: _sectionKeys[index],
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

// ========== NÚT NỔI MỞ RỘNG/THU GỌN ==========
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: 56,
      width: isExpanded
          ? (MediaQuery.of(context).size.width - 20).clamp(0, 260)
          : 56,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: isExpanded
            ? Row(
                children: [
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onNavigate,
                    child: const Text(
                      'Truy cập không gian',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggle,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: IconButton(
                  icon: const Icon(Icons.rocket_launch, color: Colors.white),
                  onPressed: onToggle,
                ),
              ),
      ),
    );
  }
}

// ---------- GLASS CARD (đã tăng độ trong suốt thật sự) ----------
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
    // Blur mạnh hơn hẳn để hiệu ứng kính mờ thật sự rõ nét
    this.blur = 22,
    // Opacity nền thấp hơn nhiều -> nhìn xuyên thấu tốt hơn
    this.opacity = 0.10,
    this.borderColor,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            // Gradient nhẹ thay vì màu phẳng để mắt "đọc" được độ trong suốt
            // ngay cả khi nền phía sau khá đồng màu.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity + 0.06),
                Colors.white.withOpacity(opacity),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.30),
              width: 1.2,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// ---------- CÁC SECTION ----------
class _NumbersSection extends StatelessWidget {
  const _NumbersSection();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'VNU là ai?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatItem(number: '1906+', label: 'Khởi nguồn ĐH Đông Dương'),
              _StatItem(number: '1993', label: 'Thành lập ĐHQGHN'),
              _StatItem(number: '8+', label: 'Trường ĐH thành viên'),
              _StatItem(number: '70.000+', label: 'Sinh viên'),
              _StatItem(number: '5.000+', label: 'Giảng viên'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      opacity: 0.06,
      child: const Column(
        children: [
          Center(
            child: Text(
              'ĐẠI HỌC QUỐC GIA HÀ NỘI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '144 Xuân Thủy, Cầu Giấy, Hà Nội',
            style: TextStyle(color: Colors.white38),
          ),
          Text(
            'Điện thoại: (024) 3754 7670',
            style: TextStyle(color: Colors.white38),
          ),
          Text(
            'Email: dhqghn@vnu.edu.vn',
            style: TextStyle(color: Colors.white38),
          ),
          SizedBox(height: 12),
          Text(
            '© 2026 Bản quyền thuộc về ĐHQGHN',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

// ========== GALLERY ẢNH: MỖI ẢNH TỰ HIỂN THỊ HIỆU ỨNG RIÊNG ==========
class _ImageGallerySection extends StatelessWidget {
  const _ImageGallerySection();

  @override
  Widget build(BuildContext context) {
    const images = [
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

    return Column(
      children: [
        _AnimatedGalleryImage(
          visibilityKey: 'gallery_img_0',
          assetPath: images[0],
          height: 200,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AnimatedGalleryImage(
                visibilityKey: 'gallery_img_1',
                assetPath: images[1],
                height: 150,
                beginOffset: const Offset(-0.15, 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AnimatedGalleryImage(
                visibilityKey: 'gallery_img_2',
                assetPath: images[2],
                height: 150,
                beginOffset: const Offset(0.15, 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 3; i < images.length; i++) ...[
          _AnimatedGalleryImage(
            visibilityKey: 'gallery_img_$i',
            assetPath: images[i],
            height: 200,
          ),
          if (i != images.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Widget ảnh gallery: tự phát hiện khi nó lọt vào vùng nhìn thấy trên màn
/// hình (nhờ [VisibilityDetector]) và tự chạy hiệu ứng fade + slide + scale
/// của RIÊNG NÓ, độc lập với các ảnh khác.
class _AnimatedGalleryImage extends StatefulWidget {
  final String visibilityKey;
  final String assetPath;
  final double height;
  final Offset beginOffset;

  const _AnimatedGalleryImage({
    required this.visibilityKey,
    required this.assetPath,
    this.height = 200,
    this.beginOffset = const Offset(0, 0.15),
  });

  @override
  State<_AnimatedGalleryImage> createState() => _AnimatedGalleryImageState();
}

class _AnimatedGalleryImageState extends State<_AnimatedGalleryImage>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    // Controller cho tia sáng "gương" chạy chéo qua ảnh
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    // Chỉ cần ảnh lộ ra >10% là bắt đầu tự chạy hiệu ứng của riêng nó.
    if (!_isVisible && info.visibleFraction > 0.1) {
      setState(() => _isVisible = true);
      // Đợi ảnh fade/slide vào xong rồi mới cho tia sáng gương lướt qua 1 lần.
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) _shineController.forward(from: 0);
      });
    }
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
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        opacity: _isVisible ? 1.0 : 0.0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          offset: _isVisible ? Offset.zero : widget.beginOffset,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            scale: _isVisible ? 1.0 : 0.92,
            child: _buildGlassyImage(widget.assetPath, height: widget.height),
          ),
        ),
      ),
    );
  }

  /// Card chỉ chứa ảnh -> để "trong suốt" thật sự thì phải:
  /// 1) Đặt BackdropFilter LÀM LỚP DƯỚI CÙNG để nó blur đúng nội dung phía
  ///    sau card (video/gradient nền), giống hệt cơ chế của _GlassCard.
  /// 2) Vẽ ảnh CHỒNG LÊN với Opacity < 1 (không phải toàn bộ ảnh mờ blur,
  ///    mà là ảnh được "hoà" một phần vào lớp kính mờ phía dưới) -> vừa
  ///    thấy rõ ảnh, vừa có cảm giác xuyên thấu như kính.
  /// 3) Thêm dải sáng chéo (shine) quét qua 1 lần -> tạo hiệu ứng "gương".
  Widget _buildGlassyImage(String assetPath, {double height = 200}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1) Lớp kính mờ dưới cùng: blur những gì phía sau card
                //    (video/gradient nền của toàn màn hình).
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(color: Colors.white.withOpacity(0.04)),
                ),

                // 2) Ảnh, để opacity <1 để vẫn "ánh" được lớp mờ phía dưới
                //    qua các vùng sáng/nhạt của ảnh -> tạo cảm giác trong suốt
                //    thay vì một tấm ảnh đặc hoàn toàn.
                Opacity(
                  opacity: 0.90,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white38,
                        size: 48,
                      ),
                    ),
                  ),
                ),

                // 3) Lớp phủ kính: gradient nhẹ + viền sáng + đổ bóng,
                //    giữ cảm giác "mặt kính" phủ trên ảnh.
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.16),
                        Colors.white.withOpacity(0.02),
                        Colors.black.withOpacity(0.06),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.30),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // 4) Hiệu ứng "gương": 1 dải sáng chéo quét qua ảnh 1 lần
                //    ngay sau khi ảnh xuất hiện, giống ánh phản chiếu trên kính.
                AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, _) {
                    final t = _shineController.value;
                    // Đi từ ngoài trái sang ngoài phải khung ảnh
                    final dx =
                        -w * 0.6 + (w * 1.6) * Curves.easeInOut.transform(t);
                    return Positioned(
                      top: -40,
                      bottom: -40,
                      left: dx,
                      width: w * 0.35,
                      child: Transform.rotate(
                        angle: -0.35, // nghiêng dải sáng cho giống ánh gương
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.35),
                                Colors.white.withOpacity(0.0),
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

class _StatItem extends StatelessWidget {
  final String number;
  final String label;
  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA5D6A7),
              letterSpacing: -0.8,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LifeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LifeItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 36, color: const Color(0xFFA5D6A7)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final int step;
  final String text;
  const _TimelineItem({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF81C784),
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF81C784),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
