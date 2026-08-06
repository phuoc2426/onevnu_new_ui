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
  });

  final bool scrollToTemporaryAddress;

  @override
  State<VcoreProfilePersonInfoView> createState() =>
      _VcoreProfilePersonInfoViewState();
}

class _VcoreProfilePersonInfoViewState
    extends State<VcoreProfilePersonInfoView> {
  final GlobalKey _temporaryAddressSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.scrollToTemporaryAddress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTemporaryAddress();
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

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller =
        Get.put(VcoreProfilePersonInfoController());

    const double spaceItem = 10;

    return ProgressHubWidget(
      contextComplete: (BuildContext hubContext) {
        controller.context = hubContext;
      },
      child: VcoreModuleScaffold(
        title: 'Thông tin cá nhân',
        body: ContainerAutoDissmis(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const VcoreProfilePersonInfoWidget(),
                spaceHeight(spaceItem),
                const VcoreProfilePersonBasicWidget(),
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

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: BlueButton(
                    title: 'Cập nhật',
                    height: 48,
                    action: () {
                      controller.updatePersonInfo();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
