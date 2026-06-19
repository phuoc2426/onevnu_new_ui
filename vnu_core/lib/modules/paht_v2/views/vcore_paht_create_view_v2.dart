import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/modules/paht_v2/controllers/vcore_paht_create_controller_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_path_create_file_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/widgets/paht_v2_section.dart';
import 'package:vnu_core/screens/vcore_select_location_view.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

class VcorePahtCreateViewV2 extends GetView<VcorePahtCreateControllerV2> {
  const VcorePahtCreateViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcorePahtCreateControllerV2>(
      init: VcorePahtCreateControllerV2(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Scaffold(
          appBar: NaviWidget(titleStr: 'Gửi phản ánh'),
          backgroundColor: const Color(0xffF6F8FB),
          body: ProgressHubWidget(
            contextComplete: (hubContext) {
              controller.context = hubContext;
            },
            child: Obx(
              () => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  children: [
                    PahtV2Section(
                      icon: Icons.grid_view_rounded,
                      title: 'Chủ đề *',
                      child: _buildChuDeSelect(controller),
                    ),
                    const SizedBox(height: 12),
                    PahtV2Section(
                      icon: Icons.account_tree_outlined,
                      title: 'Khu vực *',
                      child: _buildKhuVucSelect(controller),
                    ),
                    const SizedBox(height: 12),
                    PahtV2Section(
                      icon: Icons.location_on_outlined,
                      title: 'Địa điểm phản ánh *',
                      child: _PahtTextFieldV2(
                        hintText: 'Nhập cụ thể địa điểm',
                        onChanged: (value) {
                          controller.diaDiemPhanAnh = value.trim();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    PahtV2Section(
                      icon: Icons.map_outlined,
                      title: 'Vị trí trên bản đồ',
                      child: _buildMapPicker(controller),
                    ),
                    const SizedBox(height: 12),
                    PahtV2Section(
                      icon: Icons.subject_rounded,
                      title: 'Tiêu đề phản ánh *',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _PahtTextFieldV2(
                            hintText: 'Nhập tiêu đề phản ánh',
                            maxLines: 2,
                            onChanged: controller.onTitleChanged,
                          ),
                          const SizedBox(height: 4),
                          Text('${controller.titleLength.value}/100', style: const TextStyle(fontSize: 12, color: Color(0xff637392))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    PahtV2Section(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Nội dung phản ánh *',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _PahtTextFieldV2(
                            hintText: 'Nhập chi tiết nội dung phản ánh',
                            maxLines: 6,
                            onChanged: controller.onContentChanged,
                          ),
                          const SizedBox(height: 4),
                          Text('${controller.contentLength.value}/2000', style: const TextStyle(fontSize: 12, color: Color(0xff637392))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    PahtV2Section(
                      icon: Icons.image_outlined,
                      title: 'Ảnh/Video',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMediaActions(controller),
                          if (controller.listFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildAttachFiles(controller),
                          ],
                          const SizedBox(height: 6),
                          const Text('Tối đa 3 tệp, mỗi tệp không quá 30MB.', style: TextStyle(fontSize: 12, color: Color(0xff637392))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyNote(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colorMain,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: controller.submitPhanAnh,
                        child: const Text('Gửi phản ánh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChuDeSelect(VcorePahtCreateControllerV2 controller) {
    return VcoreDropdown2SelectWidget(
      items: controller.listChuDe.map((e) => VcoreDropdownModel(text: e.tenChuDe ?? '', guid: e.guid ?? '')).toList(),
      hint: 'Chọn chủ đề',
      selectedGuid: controller.currentChuDe.value?.guid,
      onSelected: controller.changeChuDeDropdown,
    );
  }

  Widget _buildKhuVucSelect(VcorePahtCreateControllerV2 controller) {
    return VcoreDropdown2SelectWidget(
      items: controller.listKhuVuc.map((e) => VcoreDropdownModel(text: e.tenKhuVucBanDo ?? '', guid: e.guid ?? '')).toList(),
      hint: 'Chọn khu vực',
      selectedGuid: controller.currentKhuVuc.value?.guid,
      onSelected: controller.changeKhuVucDropdown,
    );
  }

  Widget _buildMapPicker(VcorePahtCreateControllerV2 controller) {
    final location = controller.locationPoint.value;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final result = await Get.to(() => const VcoreSelectLocationView());
        if (result != null) {
          controller.locationPoint.value = result;
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xffF3F6F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffE4EAF2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.pin_drop_outlined, color: Color(0xff008B52)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location == null ? 'Chọn vị trí trên bản đồ' : '${location.latitude}, ${location.longitude}',
                style: const TextStyle(color: Color(0xff071A44), fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xff637392)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaActions(VcorePahtCreateControllerV2 controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SmallActionButton(icon: Icons.upload_file_rounded, text: 'Tải lên', onTap: controller.excPickerPhotoVideo),
        _SmallActionButton(icon: Icons.photo_camera_outlined, text: 'Chụp ảnh', onTap: controller.excCamera),
        _SmallActionButton(icon: Icons.videocam_outlined, text: 'Quay video', onTap: controller.excCameraVideo),
      ],
    );
  }

  Widget _buildAttachFiles(VcorePahtCreateControllerV2 controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: controller.listFiles.length,
      itemBuilder: (ctx, index) {
        final file = controller.listFiles[index];
        return VcorePathCreateFileViewV2(
          fileUploadModel: file,
          onDelete: () => controller.listFiles.removeAt(index),
        );
      },
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffECFFF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffBFEAD7)),
      ),
      child: const Text(
        'Thông tin của bạn được bảo mật và chỉ sử dụng cho mục đích xử lý phản ánh.',
        style: TextStyle(color: Color(0xff146C43), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PahtTextFieldV2 extends StatelessWidget {
  final String hintText;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _PahtTextFieldV2({
    required this.hintText,
    this.maxLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffE4EAF2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffE4EAF2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.colorMain, width: 1.4)),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SmallActionButton({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.colorMain,
        side: const BorderSide(color: Color(0xffBFEAD7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
