import 'package:flutter/material.dart';

/// Luồng Applicant mới không tự cấp mật khẩu.
/// Thí sinh đăng nhập trực tiếp bằng CCCD + số điện thoại trong danh sách trúng tuyển.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ đăng nhập')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 36, color: Color(0xFF078B3E)),
                  SizedBox(height: 16),
                  Text(
                    'Không cần đăng ký hoặc lấy mật khẩu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Bạn đăng nhập bằng số CCCD và số điện thoại đã cung cấp '
                    'cho nhà trường. Nếu hệ thống chưa nhận diện được thông tin, '
                    'vui lòng liên hệ bộ phận tuyển sinh để cập nhật danh sách trúng tuyển.',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
