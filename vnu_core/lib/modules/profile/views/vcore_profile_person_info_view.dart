import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_basic_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_dangvien_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_diachi_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_diachitamtru_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_doanvien_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_hokhau_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_info_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_nhaphoc_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_nhapngu_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_noiohientai_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_noisinh_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_phone_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_quequan_widget.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreProfilePersonInfoView extends StatefulWidget {
  const VcoreProfilePersonInfoView({
    super.key,
    this.scrollToTemporaryAddress = false,
    this.scrollToCccd = false,
    this.verifyCccdForKtx = false,
  });

  final bool scrollToTemporaryAddress;
  final bool scrollToCccd;
  final bool verifyCccdForKtx;

  @override
  State<VcoreProfilePersonInfoView> createState() =>
      _VcoreProfilePersonInfoViewState();
}

class _VcoreProfilePersonInfoViewState
    extends State<VcoreProfilePersonInfoView> {
  final GlobalKey _temporaryAddressSectionKey = GlobalKey();
  final GlobalKey _cccdSectionKey = GlobalKey();
  final GlobalKey _updateButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.scrollToTemporaryAddress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTemporaryAddress();
      });
    }
    if (widget.scrollToCccd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCccd();
      });
    }
  }

  Future<void> _scrollToTemporaryAddress({int attempt = 0}) async {
    await Future<void>.delayed(
      Duration(milliseconds: attempt == 0 ? 260 : 180),
    );
    if (!mounted) return;

    final BuildContext? targetContext =
        _temporaryAddressSectionKey.currentContext;
    if (targetContext == null) {
      if (attempt < 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTemporaryAddress(attempt: attempt + 1);
        });
      }
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _scrollToCccd({int attempt = 0}) async {
    await Future<void>.delayed(
      Duration(milliseconds: attempt == 0 ? 320 : 180),
    );
    if (!mounted) return;

    final BuildContext? targetContext = _cccdSectionKey.currentContext;
    if (targetContext == null) {
      if (attempt < 3) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCccd(attempt: attempt + 1);
        });
      }
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _scrollToUpdateButton({int attempt = 0}) async {
    final BuildContext? targetContext = _updateButtonKey.currentContext;
    if (targetContext == null) {
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (mounted) return _scrollToUpdateButton(attempt: attempt + 1);
      }
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      alignment: 0.90,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<VcoreProfilePersonInfoController>()) {
      Get.find<VcoreProfilePersonInfoController>()
          .clearCccdVerificationContext();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller =
        Get.put(VcoreProfilePersonInfoController());
    controller.requireCccdVerificationForKtx.value =
        widget.verifyCccdForKtx;

    const double spaceItem = 10;

    return ProgressHubWidget(
      contextComplete: (BuildContext hubContext) {
        controller.context = hubContext;
      },
      child: VcoreModuleScaffold(
        title: 'Thông tin cá nhân',
        body: Stack(
          children: <Widget>[
            ContainerAutoDissmis(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const VcoreProfilePersonInfoWidget(),
                    spaceHeight(spaceItem),
                    VcoreProfilePersonBasicWidget(
                      cccdSectionKey: _cccdSectionKey,
                    ),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonQuequanWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonNoisinhWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonHokhauWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonNoiOHienTaiWidget(),
                    spaceHeight(spaceItem),
                    KeyedSubtree(
                      key: _temporaryAddressSectionKey,
                      child: const VcoreProfilePersonDiaChiTamTruWidget(),
                    ),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonDiaChiLienLacWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonPhoneWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonNhapNguWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonDoanVienWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonDangVienWidget(),
                    spaceHeight(spaceItem),
                    const VcoreProfilePersonNhapHocWidget(),
                    spaceHeight(spaceItem),
                    KeyedSubtree(
                      key: _updateButtonKey,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BlueButton(
                          title: 'Cập nhật',
                          height: 48,
                          action: () {
                            controller.updatePersonInfo();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (!controller.hasUnsavedChanges.value) {
                return const SizedBox.shrink();
              }
              return Positioned(
                right: 14,
                bottom: 18,
                child: _FloatingUpdateArrow(
                  onTap: () {
                    _scrollToUpdateButton();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FloatingUpdateArrow extends StatefulWidget {
  const _FloatingUpdateArrow({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FloatingUpdateArrow> createState() => _FloatingUpdateArrowState();
}

class _FloatingUpdateArrowState extends State<_FloatingUpdateArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.38,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, 0.14),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 178),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
              decoration: BoxDecoration(
                color: const Color(0xFF0C63A7).withOpacity(0.94),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Có thay đổi chưa lưu\nNhấn để tới Cập nhật',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
