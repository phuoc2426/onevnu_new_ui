import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/models/phan_anh_hien_truong_model.dart';
import 'package:vnu_core/modules/paht_v2/controllers/vcore_paht_detail_controller_v2.dart';
import 'package:vnu_core/modules/paht_v2/widgets/paht_v2_section.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

class VcorePahtDetailViewV2 extends GetView<VcorePahtDetailControllerV2> {
  final PhanAnhHienTruongModel phanAnhHienTruongModel;
  final bool isChuaXuLy;

  const VcorePahtDetailViewV2({
    super.key,
    required this.phanAnhHienTruongModel,
    required this.isChuaXuLy,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcorePahtDetailControllerV2>(
      init: VcorePahtDetailControllerV2(),
      tag: const Uuid().v4(),
      builder: (controller) {
        controller.configWithModel(phanAnhHienTruongModel);
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            appBar: NaviWidget(titleStr: 'Thông tin chi tiết'),
            backgroundColor: const Color(0xffF6F8FB),
            body: Obx(
              () {
                final model = controller.model.value;
                if (model == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SafeArea(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, (isChuaXuLy && controller.enableDelete.value) ? 96 : 24),
                        child: Column(
                          children: [
                            PahtV2Section(
                              icon: Icons.campaign_outlined,
                              title: model.tieuDePhanAnh ?? '',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow('Chủ đề:', model.tenChuDe ?? ''),
                                  _infoRow(
                                    'Ngày gửi:',
                                    DateTimeUtils.stringFromDateTime(model.thoiGianGui, DateTimeConst.U_MINUTE_AFTER_FORMAT),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      if (model.containtMapLocation() == true) {
                                        final map = 'https://maps.google.com/?q=${model.mapDiaDiemPhanAnh}&z=8';
                                        Utils.openUrl(map);
                                      }
                                    },
                                    child: _infoRow('Địa điểm:', model.diaDiemPhanAnh ?? '', link: model.containtMapLocation() == true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            PahtV2Section(
                              icon: Icons.notes_rounded,
                              title: 'Nội dung phản ánh',
                              child: Text(
                                model.noiDungPhanAnh ?? '',
                                style: const TextStyle(fontSize: 14, color: Color(0xff071A44), height: 1.45),
                              ),
                            ),
                            if ((model.fileDinhKemsPhanAnh ?? []).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              PahtV2Section(
                                icon: Icons.attach_file_rounded,
                                title: 'Tệp phản ánh',
                                child: _buildFiles(controller, model.fileDinhKemsPhanAnh ?? []),
                              ),
                            ],
                            if (controller.xylyModel.value != null) ...[
                              const SizedBox(height: 12),
                              PahtV2Section(
                                icon: Icons.verified_outlined,
                                title: 'Kết quả xử lý',
                                child: _buildXuLy(controller),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isChuaXuLy && controller.enableDelete.value)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: controller.deletePaht,
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              label: const Text('Xoá phản ánh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, {bool link = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff637392))),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: link ? AppTheme.colorMain : const Color(0xff071A44),
                fontWeight: FontWeight.w600,
                decoration: link ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiles(VcorePahtDetailControllerV2 controller, Iterable files) {
    return Column(
      children: files.map((file) {
        final dynamic item = file;
        final String name = item.name ?? 'Tệp đính kèm';
        final String guid = item.guid ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffF3F6F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, color: Color(0xff637392)),
              const SizedBox(width: 8),
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(
                onPressed: () => controller.downloadAndOpen(item),
                icon: const Icon(Icons.open_in_new_rounded),
              ),
              IconButton(
                onPressed: () => controller.downloadAndShare(guid, name),
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildXuLy(VcorePahtDetailControllerV2 controller) {
    final PhanAnhHienTruongXuLyModel? xyLy = controller.xylyModel.value;
    if (xyLy == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          xyLy.noiDungXuLy ?? '',
          style: const TextStyle(fontSize: 14, color: Color(0xff071A44), height: 1.45),
        ),
        const SizedBox(height: 10),
        _infoRow(
          'Ngày trả lời:',
          DateTimeUtils.stringFromDateTime(xyLy.thoiGianTraLoi, DateTimeConst.U_MINUTE_AFTER_FORMAT),
        ),
        if ((xyLy.fileDinhKemsXuLy ?? []).isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildFiles(controller, xyLy.fileDinhKemsXuLy ?? []),
        ],
      ],
    );
  }
}
