import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:vnu_core/modules/student_card/controllers/vcore_student_card_controller.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import 'widgets/y_only_card.dart';
import 'widgets/card_face_front.dart';
import 'widgets/card_face_back.dart';

class VcoreStudentCardView extends GetView<VcoreStudentCardController> {
  const VcoreStudentCardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng 1 instance ổn định, tránh tạo/hủy lại controller khi rebuild
    return GetBuilder<VcoreStudentCardController>(
      init: Get.put(VcoreStudentCardController(), permanent: false),
      builder: (c) {
        return ProgressHubWidget(
          contextComplete: (hubContext) => c.context = hubContext,
          child: _StudentCardScaffold(controller: c),
        );
      },
    );
  }
}

class _StudentCardScaffold extends StatefulWidget {
  const _StudentCardScaffold({required this.controller});
  final VcoreStudentCardController controller;

  @override
  State<_StudentCardScaffold> createState() => _StudentCardScaffoldState();


}

class _StudentCardScaffoldState extends State<_StudentCardScaffold>
    with TickerProviderStateMixin {
  late final AnimationController _flipCtrl;   // 0 -> π
  late final Animation<double> _angleAnim;    // radians

  VcoreStudentCardController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _angleAnim = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    )..addListener(() {
      // Đồng bộ góc về controller để tooltip/icon và logic isBack cập nhật
      c.setAngle(_angleAnim.value);
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() => c.isBack ? _flipCtrl.reverse() : _flipCtrl.forward();

  @override
  Widget build(BuildContext context) {
    // Lắng nghe update() từ controller (isLoading + dữ liệu + góc)
    return GetBuilder<VcoreStudentCardController>(builder: (_) {
      final size = MediaQuery.of(context).size;
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      final containerH = isLandscape ? size.height * .78 : size.height * .66;
      final cardW = math.min(560.0, size.width * (isLandscape ? .7 : .9));
      final cardH = cardW / VcoreStudentCardController.aspect;

      // Helper đọc map an toàn (không dùng '!')
      String v(String key) {
        final raw = c.thongTinSinhVien[key];
        if (raw == null) return '';
        final s = raw.toString().trim();
        return s == 'null' ? '' : s;
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Thẻ sinh viên'),
          actions: [
            IconButton(
              tooltip: 'Căn giữa & reset zoom',
              onPressed: () => c.recenter(this),
              icon: const Icon(Icons.center_focus_strong),
            ),
            IconButton(
              tooltip: c.isBack ? 'Quay về mặt trước' : 'Xoay ra mặt sau',
              onPressed: _toggleFlip,
              icon: Icon(c.isBack ? Icons.flip_to_front : Icons.flip),
            ),
          ],
          backgroundColor: Color.fromRGBO(24, 210, 67, 1.0),
        ),
        backgroundColor: const Color(0xffffffff),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SizedBox(
                    height: containerH,
                    child: InteractiveViewer(
                      transformationController: c.transform,
                      minScale: 0.5,
                      maxScale: 8,
                      panEnabled: false,
                      scaleEnabled: true,
                      boundaryMargin: const EdgeInsets.all(140),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _angleAnim,
                          builder: (context, child) => YOnlyCard(
                            width: cardW,
                            height: cardH,
                            angleY: _angleAnim.value,
                            matrixProvider: c.matrixFor,
                            isBackProvider: c.isBackFrom,
                            front: CardFaceFront(
                              hoTen: v('hoTen'),
                              maSV: v('maSV'),
                              ngaySinh: v('ngaySinh'),
                              GT: v('GT'),
                              khoaHoc: v('khoaHoc'),
                              khoa: v('khoa'),
                              He:"gegeg",
                              HSD:"HSD",
                              tenDonVi: v('tenDonVi'),
                              iconDonVi: Icon(
                                Icons.business,
                                size: 32,
                                color: Colors.blue,
                              ),
                              chuongTrinhDaoTao: v('chuongTrinhDaoTao'),
                              nganhHoc: v('nganhHoc'),
                            ),
                            back: CardFaceBack(
                              // tenDonVi: "tên đơn vị",
                              // He: v('He'),
                              // HSD: v('HSD'),
                              // chuongTrinhDaoTao: v('chuongTrinhDaoTao'),
                              // nganhHoc: v('nganhHoc'),
                              // khoaHoc: v('khoaHoc'),
                              // khoa: v('khoa'),
                              // maSV: v('maSV'),
                              // ngaySinh: v('ngaySinh'),
                              // GT: v('GT'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Overlay loading theo flag trong controller
            if (c.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
    });
  }
}
