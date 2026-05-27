import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_family_info_controller.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_person_info_controller.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import 'widget/vcore_profile_family_anhem_widget.dart';
import 'widget/vcore_profile_family_con_widget.dart';
import 'widget/vcore_profile_family_father_widget.dart';
import 'widget/vcore_profile_family_mother_widget.dart';
import 'widget/vcore_profile_family_thanhphan_widget.dart';
import 'widget/vcore_profile_family_vochong_widget.dart';

import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreProfileFamilyInfoView
    extends GetView<VcoreProfileFamilyInfoController> {
  const VcoreProfileFamilyInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final VcoreProfileFamilyInfoController controller =
        Get.put(VcoreProfileFamilyInfoController());

    const spaceItem = 10.0;

    return ProgressHubWidget(
      contextComplete: (hubContext) {
        controller.context = hubContext;
      },
      child: VcoreModuleScaffold(
        title: "Thông tin gia đình",
        body: SingleChildScrollView(
          child: ContainerAutoDissmis(
            child: Column(
              children: [
                const VcoreProfileFamilyThanhphanWidget(),
                spaceHeight(spaceItem),

                const VcoreProfileFamilyFatherWidget(),
                spaceHeight(spaceItem),

                const VcoreProfileFamilyMotherWidget(),
                spaceHeight(spaceItem),

                const VcoreProfileFamilyVoChongWidget(),
                spaceHeight(spaceItem),

                const VcoreProfileFamilyAnhEmWidget(),
                spaceHeight(spaceItem),

                const VcoreProfileFamilyConWidget(),
                spaceHeight(spaceItem),

                //Cap nhat
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BlueButton(
                    title: 'Cập nhật',
                    height: 48,
                    action: () {
                      controller.updateFamilyInfo();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
