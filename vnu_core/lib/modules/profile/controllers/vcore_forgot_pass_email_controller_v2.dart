import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/globals.dart';

class VcoreForgotPassEmailControllerV2 extends GetxController {
  static const String recipientEmail = 'vnunet@vnu.edu.vn';
  static const MethodChannel gmailChannel = MethodChannel('gmail_sender');

  final subjectController = TextEditingController();
  final bodyController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final RxList<XFile> images = <XFile>[].obs;

  final RxBool isSending = false.obs;
  final RxnBool gmailInstalled = RxnBool();

  final RxString hoTen = ''.obs;
  final RxString maSinhVien = ''.obs;
  final RxString emailVnu = ''.obs;
  final RxString emailCaNhan = ''.obs;
  final RxString soDienThoai = ''.obs;
  final RxString donVi = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadStudentInfoFromCache();
    buildDefaultMailContent();
    // checkGmailInstalled();
  }

  @override
  void onClose() {
    subjectController.dispose();
    bodyController.dispose();
    super.onClose();
  }

  void loadStudentInfoFromCache() {
    final student = Globals().thongTinSinhVienModel.value;
    final currentUser = Globals().currentUserModel.value;
    final lopDaoTao = Globals().lopDaoTaoModel.value;

    final rawMaSinhVien = student?.maSinhVien?.toString().trim() ?? '';

    hoTen.value = firstNotEmpty([
      student?.hoVaTen?.toString(),
      currentUser?.hoVaTen?.toString(),
    ]);

    maSinhVien.value = rawMaSinhVien;

    emailVnu.value = rawMaSinhVien.isNotEmpty
        ? '${rawMaSinhVien.toLowerCase()}@vnu.edu.vn'
        : '';

    emailCaNhan.value = firstNotEmpty([
      currentUser?.email?.toString(),
      student?.emailKhac?.toString(),
      student?.email?.toString(),
    ]);

    soDienThoai.value = firstNotEmpty([
      currentUser?.soDienThoai?.toString(),
      student?.mobile?.toString(),
      student?.tel?.toString(),
    ]);

    donVi.value = lopDaoTao?.ten?.toString().trim() ?? '';
  }

  String firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  void buildDefaultMailContent() {
    subjectController.text = buildSubject();
    bodyController.text = buildBody();
  }

  String buildSubject() {
    if (maSinhVien.value.isNotEmpty && hoTen.value.isNotEmpty) {
      return 'Yêu cầu cấp lại mật khẩu email VNU - ${maSinhVien.value} - ${hoTen.value}';
    }

    if (maSinhVien.value.isNotEmpty) {
      return 'Yêu cầu cấp lại mật khẩu email VNU - ${maSinhVien.value}';
    }

    return 'Yêu cầu cấp lại mật khẩu email VNU';
  }

  String valueOrBlank(String value) {
    final text = value.trim();
    return text.isNotEmpty ? text : 'Chưa có thông tin';
  }

  String buildBody() {
    return '''
Kính gửi bộ phận hỗ trợ VNUNet,

Em/Tôi xin đề nghị được hỗ trợ cấp lại mật khẩu email VNU.

Thông tin cá nhân:
- Họ và tên: ${valueOrBlank(hoTen.value)}
- Mã sinh viên/Học viên/Nghiên cứu sinh: ${valueOrBlank(maSinhVien.value)}
- Email VNU cần cấp lại mật khẩu: ${valueOrBlank(emailVnu.value)}
- Email cá nhân dùng để nhận phản hồi: ${valueOrBlank(emailCaNhan.value)}
- Số điện thoại liên hệ: ${valueOrBlank(soDienThoai.value)}
- Đơn vị/Lớp/Khoa/Trường: ${valueOrBlank(donVi.value)}

Em/Tôi xin gửi kèm các ảnh xác minh:
1. Thẻ sinh viên/học viên/nghiên cứu sinh chụp rõ 2 mặt.
2. CCCD/CMND chụp rõ 2 mặt.
3. Ảnh chân dung cầm thẻ sinh viên và CCCD/CMND kề sát khuôn mặt.

Trường hợp chưa được cấp hoặc bị mất thẻ sinh viên, em/tôi xin gửi kèm bản mềm hoặc minh chứng liên quan.

Sau khi xác thực thông tin chính xác, kính mong quản trị viên VNU hỗ trợ cấp lại mật khẩu mới và phản hồi qua email cá nhân nêu trên.

Em/Tôi xin cảm ơn.
''';
  }

  Future<void> checkGmailInstalled() async {
    if (!Platform.isAndroid) {
      gmailInstalled.value = null;
      return;
    }

    try {
      final installed =
          await gmailChannel.invokeMethod<bool>('isGmailInstalled') ?? false;
      gmailInstalled.value = installed;
    } catch (_) {
      gmailInstalled.value = false;
    }
  }

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty) return;

    images.addAll(picked);
  }

  void removeImageAt(int index) {
    images.removeAt(index);
  }

  void refreshMailContentFromCache() {
    loadStudentInfoFromCache();
    buildDefaultMailContent();
    showSuccess('Đã cập nhật lại nội dung từ thông tin sinh viên.');
  }

  Future<void> copyManualContent() async {
    final text = '''To: $recipientEmail
Subject: ${subjectController.text.trim()}

${bodyController.text.trim()}''';

    await Clipboard.setData(ClipboardData(text: text));
    showSuccess('Đã copy nội dung gửi mail.');
  }

  Future<void> sendEmail(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (maSinhVien.value.trim().isEmpty) {
      showMailGuide(
        context,
        title: 'Thiếu mã sinh viên',
        message:
        'Chưa tìm thấy mã sinh viên trong cache. Vui lòng bổ sung mã sinh viên trong nội dung email trước khi gửi.',
      );
      return;
    }

    isSending.value = true;

    try {
      if (Platform.isAndroid) {
        await sendWithGmailAndroid(context);
      } else if (Platform.isIOS) {
        await sendWithIosMailComposer(context);
      } else {
        await copyManualContent();
        if (!context.mounted) return;
        showMailGuide(
          context,
          title: 'Không hỗ trợ nền tảng này',
          message: 'Nội dung email đã được copy. Vui lòng gửi thủ công.',
        );
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendWithGmailAndroid(BuildContext context) async {
    try {
      final attachmentPaths = images.map((x) => x.path).toList();

      debugPrint('Calling sendToGmail...');
      debugPrint('attachments: $attachmentPaths');

      await gmailChannel.invokeMethod('sendToGmail', {
        'to': recipientEmail,
        'subject': subjectController.text.trim(),
        'body': bodyController.text.trim(),
        'attachmentPaths': attachmentPaths,
      });
    } on PlatformException catch (e) {
      debugPrint(
        'sendToGmail PlatformException: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      await copyManualContent();

      if (!context.mounted) return;

      showMailGuide(
        context,
        title: 'Không mở được Gmail',
        message:
        e.message ?? 'Không thể mở Gmail. Nội dung email đã được copy.',
      );
    } catch (e) {
      debugPrint('sendToGmail error: $e');
      await copyManualContent();

      if (!context.mounted) return;

      showMailGuide(
        context,
        title: 'Không mở được Gmail',
        message: 'Không thể mở Gmail. Nội dung email đã được copy.',
      );
    }
  }
  Future<void> sendWithIosMailComposer(BuildContext context) async {
    try {
      final email = Email(
        recipients: const [recipientEmail],
        subject: subjectController.text.trim(),
        body: bodyController.text.trim(),
        attachmentPaths: images.map((x) => x.path).toList(),
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
    } catch (_) {
      await copyManualContent();
      if (!context.mounted) return;

      showMailGuide(
        context,
        title: 'Không mở được ứng dụng Mail',
        message:
        'Thiết bị chưa cấu hình ứng dụng Mail hoặc chưa có ứng dụng email phù hợp. Nội dung email đã được copy.',
      );
    }
  }

  Future<void> openGmailStore() async {
    final Uri uri;

    if (Platform.isIOS) {
      uri = Uri.parse(
        'https://apps.apple.com/app/gmail-email-by-google/id422689480',
      );
    } else {
      uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.gm',
      );
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void showSuccess(String message) {
    Get.snackbar(
      'Thông báo',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void showMailGuide(
      BuildContext context, {
        required String title,
        required String message,
      }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: openGmailStore,
                    icon: const Icon(Icons.download),
                    label: const Text('Tải Gmail'),
                  ),
                  OutlinedButton.icon(
                    onPressed: copyManualContent,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy nội dung'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
