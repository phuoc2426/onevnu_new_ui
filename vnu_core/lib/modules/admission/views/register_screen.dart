import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/admission/controllers/applicant_auth_controller.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dùng chung controller với login screen nếu muốn,
    // nhưng ở đây tạo instance mới để tránh xung đột.
    return GetBuilder(
      init: ApplicantAuthController(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            // Để AppBar trong suốt và đè lên background nếu cần
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF111318)),
            ),
            body: Stack(
              children: [
                // 1. LỚP BACKGROUND CHỜ SẴN
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F6F9), // Màu nền tạm thời
                    // TODO: Khi có ảnh background, bỏ comment đoạn dưới và thay tên ảnh
                    // image: DecorationImage(
                    //   image: AssetImage('assets/images/your_background.jpg'),
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                ),

                // 2. NỘI DUNG CHÍNH NỔI TRÊN NỀN
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card chứa form lấy mật khẩu (Style giống DRStep4ReviewScreen)
                        Card(
                          color: Colors.white,
                          elevation:
                              4, // Đẩy elevation lên một chút để nổi bật trên background
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFFE3E6EB)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tiêu đề Form
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEAF8EF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.lock_reset_outlined,
                                        color: Color(0xFF078B3E),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Lấy mật khẩu',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111318),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Vui lòng nhập số CCCD của bạn để hệ thống hỗ trợ cấp lại mật khẩu.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF666B75),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Ô nhập CCCD
                                TextField(
                                  controller: controller.cccdController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Color(0xFF111318),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Số CCCD',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF666B75),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.badge_outlined,
                                      color: Color(0xFF666B75),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFFBFCFD),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE3E6EB),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE3E6EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF078B3E),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Nút Gửi yêu cầu
                                Obx(
                                  () => controller.isLoading.value
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF078B3E),
                                          ),
                                        )
                                      : SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                controller.register(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF078B3E,
                                              ),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Gửi yêu cầu',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}
