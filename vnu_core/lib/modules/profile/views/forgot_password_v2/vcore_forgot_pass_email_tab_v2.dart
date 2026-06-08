import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_forgot_pass_email_controller_v2.dart';

class VcoreForgotPassEmailTabV2 extends StatelessWidget {
  const VcoreForgotPassEmailTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreForgotPassEmailControllerV2>(
      init: VcoreForgotPassEmailControllerV2(),
      builder: (controller) {
        return Obx(
              () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MailAppGuideCard(controller: controller),
              const SizedBox(height: 12),

              _StudentInfoCard(controller: controller),
              const SizedBox(height: 12),

              const _AttachmentGuideCard(),
              const SizedBox(height: 12),

              _ReadonlyInfoBox(
                label: 'Người nhận',
                value: VcoreForgotPassEmailControllerV2.recipientEmail,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: controller.subjectController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: controller.bodyController,
                minLines: 12,
                maxLines: 20,
                decoration: const InputDecoration(
                  labelText: 'Nội dung email',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: controller.refreshMailContentFromCache,
                icon: const Icon(Icons.sync),
                label: const Text('Tải lại thông tin từ cache'),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: controller.pickImages,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Chọn ảnh xác minh'),
              ),

              if (controller.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Ảnh đã chọn: ${controller.images.length}'),
                const SizedBox(height: 8),
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

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: controller.isSending.value
                    ? null
                    : () => controller.sendEmail(context),
                icon: controller.isSending.value
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                label: const Text('Mở ứng dụng email để gửi'),
              ),

              const SizedBox(height: 8),

              TextButton.icon(
                onPressed: controller.copyManualContent,
                icon: const Icon(Icons.copy),
                label: const Text('Copy nội dung email'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MailAppGuideCard extends StatelessWidget {
  const _MailAppGuideCard({
    required this.controller,
  });

  final VcoreForgotPassEmailControllerV2 controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mail_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gửi email truyền thống',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Ứng dụng sẽ chuyển sẵn người nhận, tiêu đề, nội dung và ảnh xác minh sang ứng dụng email trên thiết bị.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Khuyến nghị sử dụng Gmail. Nếu thiết bị chưa có ứng dụng email, hãy cài Gmail hoặc cấu hình Mail trước khi gửi.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.openGmailStore,
              icon: const Icon(Icons.download),
              label: const Text('Tải Gmail'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  const _StudentInfoCard({
    required this.controller,
  });

  final VcoreForgotPassEmailControllerV2 controller;

  @override
  Widget build(BuildContext context) {
    final hasStudentCode = controller.maSinhVien.value.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasStudentCode
                      ? Icons.person_search_outlined
                      : Icons.warning_amber_outlined,
                  color: hasStudentCode ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Thông tin lấy từ cache sinh viên',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Họ và tên', value: controller.hoTen.value),
            _InfoRow(label: 'Mã sinh viên', value: controller.maSinhVien.value),
            _InfoRow(label: 'Email VNU', value: controller.emailVnu.value),
            _InfoRow(
              label: 'Email cá nhân',
              value: controller.emailCaNhan.value,
            ),
            _InfoRow(
              label: 'Số điện thoại',
              value: controller.soDienThoai.value,
            ),
            _InfoRow(label: 'Đơn vị/Lớp', value: controller.donVi.value),
            if (!hasStudentCode) ...[
              const SizedBox(height: 8),
              const Text(
                'Chưa tìm thấy mã sinh viên trong cache. Vui lòng bổ sung mã sinh viên trong nội dung email trước khi gửi.',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isNotEmpty ? value.trim() : 'Chưa có';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(displayValue),
          ),
        ],
      ),
    );
  }
}

class _AttachmentGuideCard extends StatelessWidget {
  const _AttachmentGuideCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Ảnh cần đính kèm:\n'
              '1. Thẻ sinh viên/học viên/nghiên cứu sinh chụp rõ 2 mặt.\n'
              '2. CCCD/CMND chụp rõ 2 mặt.\n'
              '3. Ảnh chân dung cầm thẻ sinh viên và CCCD/CMND kề sát khuôn mặt.\n\n'
              'Nếu chưa được cấp hoặc bị mất thẻ sinh viên, hãy đính kèm bản mềm hoặc minh chứng phù hợp.',
        ),
      ),
    );
  }
}

class _ReadonlyInfoBox extends StatelessWidget {
  const _ReadonlyInfoBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(value),
    );
  }
}