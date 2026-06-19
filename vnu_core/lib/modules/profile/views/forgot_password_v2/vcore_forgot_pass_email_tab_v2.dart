import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_forgot_pass_email_controller_v2.dart';

const Color _brandColor = Color(0xFF1565C0);
const Color _brandDarkColor = Color(0xFF0D47A1);

class VcoreForgotPassEmailTabV2 extends StatelessWidget {
  const VcoreForgotPassEmailTabV2({
    super.key,
    this.isEmbedded = false,
    this.prefillFromCache = true,
  });

  final bool isEmbedded;
  final bool prefillFromCache;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreForgotPassEmailControllerV2>(
      init: VcoreForgotPassEmailControllerV2(
        prefillFromCache: prefillFromCache,
      ),
      tag: prefillFromCache ? 'forgot_email_cache' : 'forgot_email_manual',
      builder: (controller) {
        return Obx(
          () => ListView(
            padding: EdgeInsets.fromLTRB(16, isEmbedded ? 0 : 12, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _MailAppGuideCard(controller: controller),
              spaceHeight(12),

              _StudentInfoInputCard(controller: controller),
              spaceHeight(12),

              const _AttachmentGuideCard(),
              spaceHeight(12),

              _ReadonlyInfoBox(
                label: 'Người nhận',
                value: VcoreForgotPassEmailControllerV2.recipientEmail,
              ),
              spaceHeight(12),

              TextField(
                controller: controller.subjectController,
                readOnly: true,
                decoration: _inputDecoration('Tiêu đề').copyWith(
                  helperText: 'Tự tạo theo thông tin đã nhập phía trên.',
                ),
              ),
              spaceHeight(12),

              TextField(
                controller: controller.bodyController,
                readOnly: true,
                keyboardType: TextInputType.multiline,
                minLines: 12,
                maxLines: null,
                decoration: _inputDecoration('Nội dung email').copyWith(
                  alignLabelWithHint: true,
                  helperText:
                      'Nội dung tự cập nhật khi nhập thông tin. Kéo màn hình để xem toàn bộ.',
                ),
              ),
              spaceHeight(12),

              Row(
                children: [
                  Expanded(
                    child: prefillFromCache
                        ? _AppOutlineButton(
                            title: 'Tải lại cache',
                            icon: Icons.sync,
                            onTap: controller.refreshMailContentFromCache,
                          )
                        : _AppOutlineButton(
                            title: 'Tạo nội dung',
                            icon: Icons.edit_note,
                            onTap: controller.refreshMailContentFromForm,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AppOutlineButton(
                      title: 'Copy nội dung',
                      icon: Icons.copy,
                      onTap: controller.copyManualContent,
                    ),
                  ),
                ],
              ),
              spaceHeight(12),

              _AppOutlineButton(
                title: 'Chọn ảnh xác minh',
                icon: Icons.image_outlined,
                onTap: controller.pickImages,
              ),
              spaceHeight(8),
              _AttachmentCountBox(count: controller.images.length),

              if (controller.images.isNotEmpty) ...[
                spaceHeight(12),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final image = controller.images[index];

                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(image.path),
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () => controller.removeImageAt(index),
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.close, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],

              spaceHeight(24),

              if (controller.canSend)
                _AppPrimaryButton(
                  title: controller.isSending.value
                      ? 'Đang mở Gmail...'
                      : 'Mở Gmail để gửi',
                  icon: controller.isSending.value ? null : Icons.send,
                  onTap: controller.isSending.value
                      ? null
                      : () => controller.sendEmail(context),
                )
              else
                const _NoticeBox(
                  icon: Icons.info_outline,
                  content:
                      'Nút gửi chỉ hiển thị khi đã chọn đủ 05 ảnh: CCCD 2 mặt, thẻ sinh viên 2 mặt và ảnh chân dung cầm thẻ.',
                ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brandColor, width: 1.4),
      ),
    );
  }
}

class _MailAppGuideCard extends StatelessWidget {
  const _MailAppGuideCard({required this.controller});

  final VcoreForgotPassEmailControllerV2 controller;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail_outline, color: _brandColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gửi yêu cầu hỗ trợ qua Gmail',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          spaceHeight(8),
          const Text(
            'Dùng khi bạn không nhớ email khôi phục hoặc không nhận được thông báo lấy lại mật khẩu.',
          ),
          spaceHeight(12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: _AppOutlineButton(
                  title: 'Tải Gmail',
                  icon: Icons.download,
                  onTap: controller.openGmailStore,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: controller.hasOpenedGmailStore.value
                    ? const Text(
                        'Không thể tải Gmail? Hãy copy nội dung các phần bên dưới và gửi trên Gmail web.',
                        style: TextStyle(color: Colors.black54),
                      )
                    : const Text(
                        'Hãy đảm bảo thông tin gửi đi là chính xác và chọn đẩy đủ ảnh xác minh.',
                        style: TextStyle(color: Colors.black54),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentInfoInputCard extends StatelessWidget {
  const _StudentInfoInputCard({required this.controller});

  final VcoreForgotPassEmailControllerV2 controller;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: _brandColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thông tin người gửi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          spaceHeight(6),
          Text(
            controller.prefillFromCache
                ? 'Thông tin được gợi ý từ hồ sơ sinh viên, có thể sửa trước khi gửi.'
                : 'Vui lòng nhập thông tin. Nội dung email bên dưới sẽ tự cập nhật theo các ô này.',
            style: const TextStyle(color: Colors.black54),
          ),
          spaceHeight(12),
          _FormInput(
            label: 'Họ và tên',
            hint: 'Nhập họ và tên',
            controller: controller.hoTenController,
            onChanged: (_) => controller.onStudentInfoChanged(),
          ),
          spaceHeight(10),
          _FormInput(
            label: 'Mã sinh viên/Học viên/NCS',
            hint: 'Nhập mã sinh viên',
            controller: controller.maSinhVienController,
            onChanged: (_) =>
                controller.onStudentInfoChanged(rebuildEmailVnu: true),
          ),
          spaceHeight(10),
          _FormInput(
            label: 'Email VNU cần cấp lại',
            hint: 'Tự tạo theo mã sinh viên',
            controller: controller.emailVnuController,
            readOnly: true,
          ),
          spaceHeight(10),
          _FormInput(
            label: 'Email cá nhân nhận phản hồi',
            hint: 'Nhập email cá nhân',
            controller: controller.emailCaNhanController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => controller.onStudentInfoChanged(),
          ),
          spaceHeight(10),
          _FormInput(
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại',
            controller: controller.soDienThoaiController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => controller.onStudentInfoChanged(),
          ),
          spaceHeight(10),
          _FormInput(
            label: 'Đơn vị/Lớp/Khoa/Trường',
            hint: 'Nhập đơn vị hoặc lớp',
            controller: controller.donViController,
            onChanged: (_) => controller.onStudentInfoChanged(),
          ),
        ],
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandColor, width: 1.4),
        ),
      ),
    );
  }
}

class _AttachmentGuideCard extends StatelessWidget {
  const _AttachmentGuideCard();

  @override
  Widget build(BuildContext context) {
    return const _WhiteCard(
      child: Text(
        'Ảnh bắt buộc cần đính kèm đủ 05 ảnh:\n'
        '1. CCCD/CMND mặt trước.\n'
        '2. CCCD/CMND mặt sau.\n'
        '3. Thẻ sinh viên/học viên/nghiên cứu sinh mặt trước.\n'
        '4. Thẻ sinh viên/học viên/nghiên cứu sinh mặt sau.\n'
        '5. Ảnh chân dung cầm thẻ sinh viên và CCCD/CMND kề sát khuôn mặt.\n\n'
        'Nếu chưa được cấp hoặc bị mất thẻ sinh viên, hãy đính kèm bản mềm hoặc minh chứng phù hợp.',
      ),
    );
  }
}

class _AttachmentCountBox extends StatelessWidget {
  const _AttachmentCountBox({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final enough = count >= VcoreForgotPassEmailControllerV2.minRequiredImages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: enough
            ? Colors.green.withOpacity(0.08)
            : Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enough
              ? Colors.green.withOpacity(0.28)
              : Colors.orange.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            enough ? Icons.check_circle_outline : Icons.info_outline,
            color: enough ? Colors.green : Colors.orange.shade800,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              enough
                  ? 'Đã chọn đủ $count ảnh. Có thể gửi yêu cầu.'
                  : 'Đã chọn $count/5 ảnh. Cần đủ 05 ảnh mới hiển thị nút gửi.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyInfoBox extends StatelessWidget {
  const _ReadonlyInfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Email nhận cố định, không cho chỉnh sửa.',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(value),
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

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _brandColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? _brandColor : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _brandColor.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
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
