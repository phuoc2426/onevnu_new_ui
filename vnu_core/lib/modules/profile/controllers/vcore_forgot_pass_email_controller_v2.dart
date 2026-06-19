import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_core/common/utils.dart';

class MailNativeResult {
  final bool success;
  final String mode;
  final String message;

  const MailNativeResult({
    required this.success,
    required this.mode,
    required this.message,
  });

  factory MailNativeResult.fromMap(dynamic raw) {
    final map = raw is Map ? raw : <dynamic, dynamic>{};

    return MailNativeResult(
      success: map['success'] == true,
      mode: map['mode']?.toString() ?? 'unknown',
      message: map['message']?.toString() ?? '',
    );
  }
}

class VcoreForgotPassEmailControllerV2 extends GetxController {
  VcoreForgotPassEmailControllerV2({this.prefillFromCache = true});

  static const String recipientEmail = 'vnunet@vnu.edu.vn';
  static const int minRequiredImages = 5;
  static const MethodChannel gmailChannel = MethodChannel('gmail_sender');

  final bool prefillFromCache;

  final hoTenController = TextEditingController();
  final maSinhVienController = TextEditingController();
  final emailVnuController = TextEditingController();
  final emailCaNhanController = TextEditingController();
  final soDienThoaiController = TextEditingController();
  final donViController = TextEditingController();

  final subjectController = TextEditingController();
  final bodyController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final RxList<XFile> images = <XFile>[].obs;

  final RxBool isSending = false.obs;
  final RxnBool gmailInstalled = RxnBool();
  final RxBool hasOpenedGmailStore = false.obs;

  bool get canSend => images.length >= minRequiredImages;
  int get missingImageCount => minRequiredImages - images.length;

  @override
  void onInit() {
    super.onInit();
    if (prefillFromCache) {
      loadStudentInfoFromCache();
    }
    buildDefaultMailContent();
    checkGmailInstalled();
  }

  @override
  void onClose() {
    hoTenController.dispose();
    maSinhVienController.dispose();
    emailVnuController.dispose();
    emailCaNhanController.dispose();
    soDienThoaiController.dispose();
    donViController.dispose();
    subjectController.dispose();
    bodyController.dispose();
    super.onClose();
  }

  void loadStudentInfoFromCache() {
    final student = Globals().thongTinSinhVienModel.value;
    final currentUser = Globals().currentUserModel.value;
    final lopDaoTao = Globals().lopDaoTaoModel.value;

    final rawMaSinhVien = student?.maSinhVien?.toString().trim() ?? '';

    hoTenController.text = firstNotEmpty([
      student?.hoVaTen?.toString(),
      currentUser?.hoVaTen?.toString(),
    ]);

    maSinhVienController.text = rawMaSinhVien;

    emailVnuController.text = rawMaSinhVien.isNotEmpty
        ? '${rawMaSinhVien.toLowerCase()}@vnu.edu.vn'
        : '';

    emailCaNhanController.text = firstNotEmpty([
      currentUser?.email?.toString(),
      student?.emailKhac?.toString(),
      student?.email?.toString(),
    ]);

    soDienThoaiController.text = firstNotEmpty([
      currentUser?.soDienThoai?.toString(),
      student?.mobile?.toString(),
      student?.tel?.toString(),
    ]);

    donViController.text = lopDaoTao?.ten?.toString().trim() ?? '';
  }

  String firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  void onStudentInfoChanged({bool rebuildEmailVnu = false}) {
    if (rebuildEmailVnu) {
      final maSinhVien = maSinhVienController.text.trim();
      emailVnuController.text = maSinhVien.isNotEmpty
          ? '${maSinhVien.toLowerCase()}@vnu.edu.vn'
          : '';
    }
    buildDefaultMailContent();
  }

  void buildDefaultMailContent() {
    subjectController.text = buildSubject();
    bodyController.text = buildBody();
  }

  void refreshMailContentFromForm() {
    buildDefaultMailContent();
    snackBarSuccess('Đã tạo lại nội dung email từ thông tin đã nhập.');
  }

  void refreshMailContentFromCache() {
    loadStudentInfoFromCache();
    buildDefaultMailContent();
    snackBarSuccess('Đã cập nhật lại nội dung từ thông tin sinh viên.');
  }

  String buildSubject() {
    final maSinhVien = maSinhVienController.text.trim();
    final hoTen = hoTenController.text.trim();

    if (maSinhVien.isNotEmpty && hoTen.isNotEmpty) {
      return 'Yêu cầu cấp lại mật khẩu email VNU - $maSinhVien - $hoTen';
    }

    if (maSinhVien.isNotEmpty) {
      return 'Yêu cầu cấp lại mật khẩu email VNU - $maSinhVien';
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

Em/Tôi xin đề nghị được hỗ trợ lấy lại mật khẩu email VNU do không nhớ email khôi phục được cấu hình trên IDP.

Thông tin cá nhân:
- Họ và tên: ${valueOrBlank(hoTenController.text)}
- Mã sinh viên/Học viên/Nghiên cứu sinh: ${valueOrBlank(maSinhVienController.text)}
- Email VNU cần cấp lại mật khẩu: ${valueOrBlank(emailVnuController.text)}
- Email cá nhân dùng để nhận phản hồi: ${valueOrBlank(emailCaNhanController.text)}
- Số điện thoại liên hệ: ${valueOrBlank(soDienThoaiController.text)}
- Đơn vị/Lớp/Khoa/Trường: ${valueOrBlank(donViController.text)}

Em/Tôi xin gửi kèm đầy đủ 05 ảnh xác minh:
1. CCCD/CMND mặt trước.
2. CCCD/CMND mặt sau.
3. Thẻ sinh viên/học viên/nghiên cứu sinh mặt trước.
4. Thẻ sinh viên/học viên/nghiên cứu sinh mặt sau.
5. Ảnh chân dung cầm thẻ sinh viên và CCCD/CMND kề sát khuôn mặt.

Trường hợp chưa được cấp hoặc bị mất thẻ sinh viên, em/tôi xin gửi kèm bản mềm hoặc minh chứng liên quan thay thế.

Sau khi xác thực thông tin chính xác, kính mong quản trị viên VNU hỗ trợ cấp lại mật khẩu mới và phản hồi qua email cá nhân nêu trên.

Em/Tôi xin cảm ơn.
''';
  }

  String? validateRequiredInfo() {
    if (hoTenController.text.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên.';
    }
    if (maSinhVienController.text.trim().isEmpty) {
      return 'Vui lòng nhập mã sinh viên/học viên/nghiên cứu sinh.';
    }
    if (emailCaNhanController.text.trim().isEmpty) {
      return 'Vui lòng nhập email cá nhân để nhận phản hồi.';
    }
    return null;
  }

  String? validateBeforeSend() {
    final infoError = validateRequiredInfo();
    if (infoError != null) return infoError;

    if (!canSend) {
      return 'Vui lòng chọn đủ 05 ảnh xác minh: CCCD 2 mặt, thẻ sinh viên 2 mặt và ảnh chân dung cầm thẻ.';
    }

    return null;
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

  Future<void> copyManualContent() async {
    final error = validateRequiredInfo();
    if (error != null) {
      snackBarWarning(error);
      return;
    }

    buildDefaultMailContent();

    final text =
        '''To: $recipientEmail
Subject: ${subjectController.text.trim()}

${bodyController.text.trim()}''';

    await Clipboard.setData(ClipboardData(text: text));
    snackBarSuccess('Đã copy nội dung gửi mail.');
  }

  Future<void> sendEmail(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final error = validateBeforeSend();
    if (error != null) {
      snackBarWarning(error);
      return;
    }

    buildDefaultMailContent();
    isSending.value = true;

    try {
      final attachmentPaths = images.map((x) => x.path).toList();

      final raw = await gmailChannel.invokeMethod('composeEmail', {
        'to': recipientEmail,
        'recipients': [recipientEmail],
        'subject': subjectController.text.trim(),
        'body': bodyController.text.trim(),
        'attachmentPaths': attachmentPaths,
        'attachments': attachmentPaths,
        'preferGmail': true,
      });

      final result = MailNativeResult.fromMap(raw);

      if (result.success) {
        snackBarSuccess(
          result.message.isNotEmpty
              ? result.message
              : 'Đã mở ứng dụng gửi email. Vui lòng kiểm tra nội dung và bấm Gửi.',
        );
      } else {
        await copyManualContent();
        snackBarWarning(
          result.message.isNotEmpty
              ? '${result.message}\nNội dung email đã được copy.'
              : 'Không thể mở ứng dụng gửi email. Nội dung email đã được copy.',
        );
      }
    } on PlatformException catch (e) {
      await copyManualContent();
      snackBarWarning('${e.message ?? e.code}\nNội dung email đã được copy.');
    } catch (e) {
      await copyManualContent();
      snackBarError('Lỗi: $e');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> openGmailStore() async {
    hasOpenedGmailStore.value = true;
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
}
