import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';

/// CẤU HÌNH BACKGROUND TẠI ĐÂY:
/// Bạn có thể thay đổi mã màu ở dưới để điều chỉnh màu nền cho toàn bộ các trang chức năng.
const Color kDefaultModuleBgColor = Color(0xFFF6F8FA);

/// Layout trang chức năng đơn giản: Logo VNU bên trái, tiêu đề bên cạnh.
class VcoreModuleScaffold extends StatelessWidget {
  /// Tên chức năng hiển thị cạnh bên Logo
  final String title;

  /// Nội dung chính của trang
  final Widget body;

  /// Có hiển thị nút quay lại không (Mặc định: true)
  final bool showBackButton;

  /// Các nút chức năng góc phải Appbar (tùy chọn)
  final List<Widget>? actions;

  /// Floating Action Button (tùy chọn)
  final Widget? floatingActionButton;

  const VcoreModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDefaultModuleBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 22,
                ),
                onPressed: () => Get.back(),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: AppFontSizes.large,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
