import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_basic_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_dangvien_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_diachi_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_doanvien_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_hokhau_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_info_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_nhaphoc_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_nhapngu_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_noiohientai_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_noisinh_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_phone_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_quequan_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_person_diachitamtru_widget.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
// import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreProfilePersonInfoView
    extends GetView<VcoreProfilePersonInfoController> {
  const VcoreProfilePersonInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfilePersonInfoController controller = Get.put(
      VcoreProfilePersonInfoController(),
    );

    const spaceItem = 10.0;

    return ProgressHubWidget(
      contextComplete: (hubContext) {
        controller.context = hubContext;
      },
      child: VcoreModuleScaffold(
        title: "Thông tin cá nhân",
        body: ContainerAutoDissmis(
          child: SingleChildScrollView(
            child: Column(
              children: [
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

                const VcoreProfilePersonDiaChiTamTruWidget(),
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

                //Cap nhat
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
