import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_noi_tru/screens/dormitory_registration/dr_my_registration_screen.dart';
import 'package:vnu_core/modules/admission/views/applicant_login_screen.dart'; // Import đúng màn hình đăng nhập thí sinh
import 'package:vnu_core/screens/vcore_admission_view.dart'; // Import Admission view

class YourSpaceScreen extends StatelessWidget {
  final String fullName;

  const YourSpaceScreen({Key? key, required this.fullName}) : super(key: key);

  // Hàm tiện ích – xóa tất cả cache applicant
  Future<void> _clearApplicantCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('applicant_access_token');
    await prefs.remove('applicant_cccd');
    await prefs.remove('applicant_email');
    await prefs.remove('applicant_fullname');
    // Xóa token khỏi DataRepository và Globals (ghi đè bằng chuỗi rỗng)
    await DataRepository().saveSecureKey(kLoginToken, '');
    Globals().token = '';
  }

  // Dialog đổi mật khẩu
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Đổi mật khẩu'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu cũ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v?.isEmpty == true
                        ? 'Vui lòng nhập'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Vui lòng nhập';
                      if (v!.length < 6) return 'Ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != newPasswordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    Utils.showProgress(context);
                    await ApiRepository().applicantChangePassword(
                      oldPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                    );
                    Utils.dismissProgress(context);
                    Navigator.pop(ctx);
                    snackBarSuccess('Đổi mật khẩu thành công');
                  } catch (e) {
                    Utils.dismissProgress(context);
                    snackBarError(e.toString());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                ),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg2.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppColors.homeBg),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildServicesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào, $fullName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: AppFontSizes.mediumLarge,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Không gian cá nhân của bạn',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: AppFontSizes.font12_5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {
            Get.bottomSheet(
              _LogoutBottomSheet(
                onConfirm: () async {
                  await _clearApplicantCache();
                  Get.offAll(() => const VcoreAdmissionView());
                },
              ),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
          icon: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 4,
                  offset: const Offset(-1, -1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: const Icon(Icons.more_horiz, color: AppColors.brandGreen, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final services = [
      _ServiceItem(
        label: 'Nội trú',
        icon: Icons.home_work_rounded,
        color: const Color(0xFFBF5AF2),
      ),
      // Thêm các dịch vụ khác ở đây
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'DỊCH VỤ CỦA BẠN',
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize: AppFontSizes.mediumSmall,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) =>
              _buildServiceCard(context, services[index]),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, _ServiceItem item) {
    return GestureDetector(
      onTap: () {
        // Nếu là Nội trú, chuyển thẳng đến view đăng ký, không hiện bottom sheet
        if (item.label == 'Nội trú') {
          Get.to(() => const DRMyRegistrationScreen());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withOpacity(0.08),
                    item.color.withOpacity(0.18),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 6,
                    offset: const Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: item.color.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(3, 5),
                  ),
                ],
              ),
              child: Icon(item.icon, size: 26, color: item.color),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.darkNavy,
                  fontSize: AppFontSizes.font11_5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ServiceItem {
  final String label;
  final IconData icon;
  final Color color;

  const _ServiceItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

// Bottom sheet widget for logout confirmation
class _LogoutBottomSheet extends StatelessWidget {
  final VoidCallback onConfirm;

  const _LogoutBottomSheet({Key? key, required this.onConfirm})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn có chắc muốn đăng xuất?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lưu ý: Đừng quên ghi nhớ mật khẩu để đăng nhập lại.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng xuất'),
            onTap: () {
              Get.back(); // Đóng bottom sheet trước khi thực hiện hành động
              onConfirm();
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Hủy'),
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet widget for service options (e.g., Nội trú)
