import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:vnu_core/screens/cccd_registration_screen.dart'; // placeholder import if needed
import 'package:vnu_noi_tru/screens/dormitory_registration/dr_my_registration_screen.dart';

/// Post‑login dashboard for an applicant.
/// Shows a welcome message and a button to register for dormitory ("Đăng ký nội trú").
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VnuModuleAppBar(title: 'Bảng điều khiển'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chào mừng! Bạn đã đăng nhập thành công.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ShadButton(
              onPressed: () => Get.to(() => const DRMyRegistrationScreen()),
              backgroundColor: const Color(0xFF006B36),
              leading: const Icon(LucideIcons.home),
              child: const Text('Đăng ký nội trú'),
            ),
          ],
        ),
      ),
    );
  }
}

