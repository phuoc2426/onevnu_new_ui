import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/tong_ket_den_hien_tai_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';

import '../views/widget/vcore_profile_textfield_widget.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/constants/config.dart';
import '../views/widget/avatar_crop_widget.dart'; // Import widget crop với đường dẫn chính xác

class VcoreProfileController extends GetxController {
  RxBool isDeviceSupportBio = false.obs;
  RxBool isBioByFaceId = true.obs;

  Rxn<TongKetDenHienTaiModel> tongket = Rxn();

  //For open debug log
  final int serialTaps = 10;
  final int tapDurationInMs = 7000;

  int get timeNow => DateTime.now().millisecondsSinceEpoch;
  var startTap = DateTime.now().millisecondsSinceEpoch;

  int consecutiveTaps = 0;
  final RxList<AnhCaNhanModel> listAnhCaNhan = <AnhCaNhanModel>[].obs;
  final RxBool isChangingAvatar = false.obs;

  AnhCaNhanModel? get currentAvatar {
    if (listAnhCaNhan.isEmpty) return null;
    return listAnhCaNhan.first;
  }

  String get avatarUrl {
    final guid = currentAvatar?.guid ?? '';

    if (guid.isEmpty) {
      return 'https://vnu.edu.vn/upload/2014/11/17202/image/Logo-VNU-1995.jpg';
    }

    return '${ServicesUrl().baseUrlFileDownload}$guid$kParamThumbImage';
  }

  Future<void> refreshAvatar() async {
    try {
      final response = await ApiRepository().getAllAnhCanNhan();
      listAnhCaNhan.value = response;
    } catch (e) {
      // logError(e.toString());
    }
  }

  @override
  void onInit() {
    super.onInit();
    refreshAvatar();
  }

  Future<void> pickAndPreviewAvatar(BuildContext context) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceBottomSheet(context),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image == null) return;

    // Hiển thị crop dialog
    await _showAvatarCropDialog(context, File(image.path));
  }

  // final GlobalKey<AvatarCropWidgetState> _cropWidgetKey = GlobalKey<AvatarCropWidgetState>();

  Future<void> _showAvatarCropDialog(
    BuildContext context,
    File imageFile,
  ) async {
    final cropWidgetKey = GlobalKey<AvatarCropWidgetState>();

    File? croppedFile;
    bool isSaving = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () {
                                    Navigator.of(dialogContext).pop(false);
                                  },
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Điều chỉnh ảnh',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final cropState =
                                        cropWidgetKey.currentState;

                                    if (cropState == null) {
                                      return;
                                    }

                                    setDialogState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      croppedFile = await cropState.cropImage();

                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop(true);
                                      }
                                    } catch (error) {
                                      setDialogState(() {
                                        isSaving = false;
                                      });

                                      if (dialogContext.mounted) {
                                        ScaffoldMessenger.of(
                                          dialogContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Không thể cắt ảnh: $error',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Lưu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AvatarCropWidget(
                          key: cropWidgetKey,
                          imageFile: imageFile,
                          cropSize: 300,
                          outputSize: 500,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Text(
                        'Kéo để chọn vị trí. Dùng hai ngón tay để phóng to hoặc thu nhỏ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Chỉ upload ảnh đã crop.
    // Tuyệt đối không fallback sang ảnh gốc.
    if (confirmed == true && croppedFile != null) {
      await changeAvatar(context, croppedFile!);
    }
  }

  Future<void> changeAvatar(BuildContext context, File newAvatarFile) async {
    if (isChangingAvatar.value) return;

    isChangingAvatar.value = true;
    Utils.showProgress(context);

    try {
      // Upload ảnh mới
      final newAvatar = await ApiRepository().uploadAnhCanNhan(newAvatarFile);

      // Lấy danh sách tất cả ảnh
      final allAvatars = await ApiRepository().getAllAnhCanNhan();

      // Xóa tất cả ảnh cũ (trừ ảnh vừa upload)
      if (allAvatars.length > 1) {
        for (final avatar in allAvatars) {
          if (avatar.guid != newAvatar.guid) {
            try {
              await ApiRepository().deleteAnhCanNhan(avatar?.guid ?? '');
            } catch (e) {
              // Log lỗi nhưng không dừng quá trình
            }
          }
        }
      }

      await refreshAvatar();

      Utils.dismissProgress(context);
      snackBarSuccess('Cập nhật ảnh đại diện thành công.');
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    } finally {
      isChangingAvatar.value = false;
    }
  }

  // Widgets cho UI
  Widget _buildImageSourceBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chọn ảnh đại diện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn ảnh từ thư viện hoặc chụp mới',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSourceOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: 'Thư viện',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSourceOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  label: 'Chụp ảnh',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Hủy'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF1E293B)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCropDialog(BuildContext context, File imageFile) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Text(
                    'Điều chỉnh ảnh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Avatar crop area
            Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 80,
                maxHeight: 400,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AvatarCropWidget(imageFile: imageFile, cropSize: 300),
              ),
            ),

            // Instructions
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                'Dùng 2 ngón tay để phóng to/thu nhỏ và kéo để di chuyển ảnh',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getTongKetDenHienTai() async {
    try {
      var response = await ApiRepository().getTongKetDenHienTai();
      if (response.isNotEmpty) {
        tongket.value = response.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  countVersionOpenLog(BuildContext context) {
    if (kDebugMode) {
      Get.to(() => TalkerScreen(talker: Globals().talker));
    }
    final now = timeNow;
    final userExceededTapDuration = now - startTap > tapDurationInMs;

    if (userExceededTapDuration) {
      consecutiveTaps = 0;
      startTap = now;
    }

    consecutiveTaps++;

    if (consecutiveTaps == serialTaps) {
      var password = "";
      final buttonWidth = MediaQuery.of(context).size.width / 4;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            actionsAlignment: MainAxisAlignment.center,
            contentPadding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 30.0),
            buttonPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 40.0, 30.0),
            content: VcoreProfileTextFieldWidget(
              title: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              value: password,
              autoFocus: true,
              onChange: (text) {
                password = text;
              },
              onSubmitted: (text) {
                password = text;
              },
            ),
            actions: [
              WhiteButton(
                width: buttonWidth,
                title: "Hủy",
                action: () {
                  Navigator.pop(context);
                },
              ),
              BlueButton(
                width: buttonWidth,
                title: "Xác nhận",
                action: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ).then((v) async {
        if (password.isEmpty) {
          return;
        }
        if (password == kLogPass) {
          Get.to(() => TalkerScreen(talker: Globals().talker));
        } else {
          snackBarError('Mật khẩu không đúng.');
        }
      });
    }
  }
}
