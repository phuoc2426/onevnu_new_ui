import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';

class VcoreForgotPassSupportTabV2 extends StatelessWidget {
  const VcoreForgotPassSupportTabV2({super.key});

  static const loginUrl = 'https://it.vnu.edu.vn/login';
  static const supportUrl = 'https://it.vnu.edu.vn/support';
  static const profileUrl = 'https://it.vnu.edu.vn/my-profile';

  void _openBrowser({
    required String title,
    required String url,
  }) {
    // Cần map đúng theo constructor thật của VcoreBrowserView trong dự án.
    Get.to(
      () => VcoreBrowserView(
        title: title,
        url: url,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Cách 1: Cổng hỗ trợ IT VNU',
          content:
              'Khuyên dùng vì bạn có thể theo dõi trạng thái xử lý ticket và trao đổi với Admin trực tiếp trên hệ thống.',
        ),
        const SizedBox(height: 12),

        _StepCard(
          title: 'Bước 1: Đăng nhập',
          content:
              'Truy cập cổng đăng nhập. Nếu không đăng nhập được email VNU, chọn đăng nhập bằng email cá nhân qua SSO Google.',
          buttonText: 'Mở cổng đăng nhập',
          onPressed: () => _openBrowser(
            title: 'Đăng nhập IT VNU',
            url: loginUrl,
          ),
        ),

        _StepCard(
          title: 'Bước 2: Tạo yêu cầu hỗ trợ',
          content:
              'Sau khi đăng nhập, truy cập mục hỗ trợ để tạo yêu cầu lấy lại mật khẩu.',
          buttonText: 'Tạo yêu cầu hỗ trợ',
          onPressed: () => _openBrowser(
            title: 'Tạo yêu cầu hỗ trợ',
            url: supportUrl,
          ),
        ),

        _StepCard(
          title: 'Bước 3: Đính kèm minh chứng',
          content:
              'Đính kèm thẻ sinh viên, CCCD 2 mặt và ảnh chân dung cầm giấy tờ. Nếu chưa có thẻ, cung cấp bản mềm hoặc minh chứng phù hợp.',
        ),

        _StepCard(
          title: 'Bước 4: Theo dõi ticket',
          content:
              'Theo dõi trạng thái xử lý trực tiếp trên hệ thống IT VNU.',
          buttonText: 'Theo dõi ticket',
          onPressed: () => _openBrowser(
            title: 'Theo dõi ticket',
            url: profileUrl,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.content,
    this.buttonText,
    this.onPressed,
  });

  final String title;
  final String content;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}