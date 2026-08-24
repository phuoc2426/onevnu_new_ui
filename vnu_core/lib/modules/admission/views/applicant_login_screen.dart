import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/admission/controllers/applicant_auth_controller.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

class ApplicantLoginScreen extends StatefulWidget {
  const ApplicantLoginScreen({Key? key}) : super(key: key);

  @override
  State<ApplicantLoginScreen> createState() => _ApplicantLoginScreenState();
}

class _ApplicantLoginScreenState extends State<ApplicantLoginScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    // Video nền sáng/trắng (đặt trong assets/videos/login_applicant.mp4)
    _videoController =
        VideoPlayerController.asset('assets/videos/login_applicant.mp4')
          ..initialize().then((_) {
            if (mounted) setState(() {});
            _videoController.play();
            _videoController.setLooping(true);
          });
    // Kiểm tra cập nhật bắt buộc khi mở màn hình admission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdate();
    });
  }

  Future<void> _checkAppUpdate() async {
    // TODO: Thay bằng API kiểm tra phiên bản thực tế khi có sẵn.
    // Hiện tại hard-code true để luôn hiển thị dialog (demo / test).
    final bool needUpdate = true;
    if (needUpdate && mounted) {
      await Utils.showForcedUpdateDialog(context);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ApplicantAuthController>(
      init: ApplicantAuthController(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,

            body: Stack(
              fit: StackFit.expand,
              children: [
                // Video nền (trắng hoặc sáng màu)
                if (_videoController.value.isInitialized)
                  VideoPlayer(_videoController)
                else
                  Container(color: Colors.grey.shade200), // nền dự phòng sáng
                // Overlay mờ nhẹ để giúp card nổi hơn (trắng mờ)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(
                          0.05,
                        ), // Giảm từ 0.2 xuống 0.05
                        Colors.white.withOpacity(0.0), // Giảm từ 0.05 xuống 0.0
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoCard(),
                          const SizedBox(height: 24),
                          _buildLoginCard(controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Card ghi chú – kính mờ sáng, chữ đen
  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dành cho thí sinh đã có trong danh sách trúng tuyển. '
                  'Sử dụng CCCD và số điện thoại đã đăng ký với nhà trường để đăng nhập.',
                  style: TextStyles.T14M.copyWith(
                    color: Colors.black87,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card đăng nhập kính mờ sáng, chữ đen, nút nổi bật
  Widget _buildLoginCard(ApplicantAuthController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tiêu đề – đen đậm
              Text(
                'Đăng nhập',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Ô Số CCCD
              TextField(
                controller: controller.cccdController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Số CCCD',
                  labelStyle: TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: Colors.black54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                cursorColor: Colors.green,
              ),
              const SizedBox(height: 16),

              // Số điện thoại đóng vai trò thông tin xác minh đăng nhập.
              TextField(
                controller: controller.phoneNumberController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Số điện thoại đã đăng ký với trường',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Colors.black54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => controller.login(),
                cursorColor: Colors.green,
              ),
              const SizedBox(height: 24),

              // Nút đăng nhập
              Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                    : SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => controller.login(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Đăng nhập'),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              Text(
                'Không đăng nhập được? Hãy kiểm tra thông tin trong danh sách '
                'trúng tuyển hoặc liên hệ bộ phận tuyển sinh của trường.',
                textAlign: TextAlign.center,
                style: TextStyles.T14M.copyWith(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
