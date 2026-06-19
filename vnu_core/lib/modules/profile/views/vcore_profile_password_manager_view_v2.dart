import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_pass_controller_v2.dart';
import 'package:vnu_core/modules/profile/views/forgot_password_v2/vcore_forgot_pass_email_tab_v2.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import 'widget/vcore_profile_dropdownfield_widget.dart';
import 'widget/vcore_profile_textfield_widget.dart';

const Color _brandColor = Color(0xFF1565C0);
const Color _brandDarkColor = Color(0xFF0D47A1);

class VcoreProfilePasswordManagerViewV2 extends StatefulWidget {
  const VcoreProfilePasswordManagerViewV2({
    super.key,
    this.initialTab = 0,
    this.isEmbedded = false,
  });

  final int initialTab;
  final bool isEmbedded;
  @override
  State<VcoreProfilePasswordManagerViewV2> createState() =>
      _VcoreProfilePasswordManagerViewV2State();
}

class _VcoreProfilePasswordManagerViewV2State
    extends State<VcoreProfilePasswordManagerViewV2>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab < 0
          ? 0
          : widget.initialTab > 2
          ? 2
          : widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToEmailTab() {
    _tabController.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreProfilePassControllerV2>(
      init: VcoreProfilePassControllerV2(),
      builder: (controller) {
        final content = Column(
          children: [
            _PasswordTabBar(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChangePasswordTab(
                    controller: controller,
                    onForgotPassword: () => _tabController.animateTo(1),
                  ),
                  _ForgotPasswordTab(
                    controller: controller,
                    onGoToEmailSupport: _goToEmailTab,
                  ),
                  const VcoreForgotPassEmailTabV2(isEmbedded: true),
                ],
              ),
            ),
          ],
        );

        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: widget.isEmbedded
              ? content
              : Scaffold(
                  appBar: NaviWidget(titleStr: 'Quản lý mật khẩu'),
                  backgroundColor: AppColor.bgColor,
                  body: content,
                ),
        );
      },
    );
  }
}

class _PasswordTabBar extends StatelessWidget {
  const _PasswordTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: TabBar(
          controller: controller,
          labelColor: Colors.white,
          unselectedLabelColor: _brandDarkColor,
          indicator: BoxDecoration(
            color: _brandColor,
            borderRadius: BorderRadius.circular(16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.lock_reset), text: 'Đổi mật khẩu'),
            Tab(icon: Icon(Icons.help_outline), text: 'Quên mật khẩu'),
            Tab(icon: Icon(Icons.mail_outline), text: 'Gửi hỗ trợ'),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordTab extends StatelessWidget {
  const _ChangePasswordTab({
    required this.controller,
    required this.onForgotPassword,
  });

  final VcoreProfilePassControllerV2 controller;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return ContainerAutoDissmis(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionCard(
            icon: Icons.lock_reset,
            title: 'Đổi mật khẩu',
            description:
                'Chọn tài khoản cần đổi mật khẩu và nhập mật khẩu hiện tại.',
            children: [
              Obx(
                () => VcoreProfileDropdownfieldWidget(
                  title: 'Loại mật khẩu',
                  hintText: 'Chọn Email VNU hoặc Đào tạo',
                  value: controller.labelOf(controller.changeLoaiMatKhau.value),
                  items: controller.listLoaiMatKhau
                      .map((e) => controller.labelOf(e))
                      .toList(),
                  onSelected: (value) {
                    final obj = controller.listLoaiMatKhau.firstWhereOrNull(
                      (e) => controller.labelOf(e) == value,
                    );

                    if (obj != null) {
                      controller.changeLoaiMatKhau.value = obj;
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              VcoreProfileTextFieldWidget(
                title: 'Mật khẩu hiện tại',
                hintText: 'Nhập mật khẩu hiện tại',
                onChange: (text) => controller.oldPassword = text.trim(),
                onSubmitted: (text) => controller.oldPassword = text.trim(),
              ),
              const SizedBox(height: 12),
              VcoreProfileTextFieldWidget(
                title: 'Mật khẩu mới',
                hintText: 'Nhập mật khẩu mới',
                onChange: (text) => controller.newPassword = text.trim(),
                onSubmitted: (text) => controller.newPassword = text.trim(),
              ),
              const SizedBox(height: 12),
              VcoreProfileTextFieldWidget(
                title: 'Nhập lại mật khẩu mới',
                hintText: 'Nhập lại mật khẩu mới',
                onChange: (text) => controller.reNewPassword = text.trim(),
                onSubmitted: (text) => controller.reNewPassword = text.trim(),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final isEmailVnu = controller.isEmailVnu(
                  controller.changeLoaiMatKhau.value,
                );

                if (!isEmailVnu) {
                  return const SizedBox.shrink();
                }

                return const _NoticeBox(
                  icon: Icons.info_outline,
                  content:
                      'Với Email VNU, thông báo xác nhận sẽ được gửi về email khôi phục tài khoản được cấu hình trên IDP. Nếu không nhớ email khôi phục, hãy làm theo hướng dẫn ở tab Gửi hỗ trợ.',
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AppOutlineButton(
                      title: 'Quên mật khẩu?',
                      icon: Icons.help_outline,
                      onTap: onForgotPassword,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AppPrimaryButton(
                      title: 'Đổi mật khẩu',
                      icon: Icons.lock_reset,
                      onTap: controller.thayDoiMatKhau,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordTab extends StatelessWidget {
  const _ForgotPasswordTab({
    required this.controller,
    required this.onGoToEmailSupport,
  });

  final VcoreProfilePassControllerV2 controller;
  final VoidCallback onGoToEmailSupport;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SectionCard(
          icon: Icons.help_outline,
          title: 'Quên mật khẩu',
          description:
              'Chọn loại mật khẩu cần lấy lại. Nếu là Email VNU, thông báo sẽ được gửi về email khôi phục được cấu hình trên IDP.',
          children: [
            Obx(
              () => VcoreProfileDropdownfieldWidget(
                title: 'Loại mật khẩu cần lấy lại',
                hintText: 'Chọn Email VNU hoặc Đào tạo',
                value: controller.labelOf(controller.forgotLoaiMatKhau.value),
                items: controller.listLoaiMatKhau
                    .map((e) => controller.labelOf(e))
                    .toList(),
                onSelected: (value) {
                  final obj = controller.listLoaiMatKhau.firstWhereOrNull(
                    (e) => controller.labelOf(e) == value,
                  );

                  if (obj != null) {
                    controller.forgotLoaiMatKhau.value = obj;
                    controller.forgotSent.value = false;
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            const _NoticeBox(
              icon: Icons.mail_lock_outlined,
              content:
                  'Không nhớ email khôi phục? Chọn “Không nhớ mail khôi phục” để gửi yêu cầu hỗ trợ qua email.',
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (!controller.forgotSent.value) {
                return _AppPrimaryButton(
                  title: 'Gửi yêu cầu',
                  icon: Icons.send,
                  onTap: controller.quenMatKhau,
                );
              }

              return _ForgotSuccessCard(
                onDone: () => controller.forgotSent.value = false,
                onGoToEmailSupport: onGoToEmailSupport,
              );
            }),
            const SizedBox(height: 12),
            _AppOutlineButton(
              title: 'Không nhớ mail khôi phục',
              icon: Icons.mail_outline,
              onTap: onGoToEmailSupport,
            ),
          ],
        ),
      ],
    );
  }
}

class _ForgotSuccessCard extends StatelessWidget {
  const _ForgotSuccessCard({
    required this.onDone,
    required this.onGoToEmailSupport,
  });

  final VoidCallback onDone;
  final VoidCallback onGoToEmailSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yêu cầu lấy lại mật khẩu đã được gửi.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Nếu là Email VNU, thông báo sẽ được gửi về email khôi phục tài khoản được cấu hình trên IDP.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AppOutlineButton(title: 'Đã hiểu', onTap: onDone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AppPrimaryButton(
                  title: 'Không nhớ mail khôi phục',
                  onTap: onGoToEmailSupport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _brandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _brandColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.semiBold.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.icon, required this.content});

  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _brandColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandColor.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _brandColor, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(content)),
        ],
      ),
    );
  }
}

class _AppPrimaryButton extends StatelessWidget {
  const _AppPrimaryButton({
    required this.title,
    required this.onTap,
    this.icon,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _brandColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _brandColor.withOpacity(0.22),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppOutlineButton extends StatelessWidget {
  const _AppOutlineButton({
    required this.title,
    required this.onTap,
    this.icon,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brandColor.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: _brandColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _brandColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
