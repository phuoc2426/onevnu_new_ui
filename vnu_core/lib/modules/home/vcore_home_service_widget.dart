import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/extensions/map_ext.dart';
import 'package:vnu_core/models/box_service_model.dart';
import 'package:vnu_core/modules/course_points/views/vcore_course_points_view.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/views/vcore_motel_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_view.dart';
import 'package:vnu_core/modules/student_card/views/vcore_student_card_view.dart';
import 'package:vnu_core/modules/time_schedule/views/vcore_time_schedule_view.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../constants/enum.dart';
import '../cam_nang/views/vcore_cam_nang_view.dart';
import '../exam_schedule/views/vcore_exam_schedule_view.dart';
import '../hdsd/views/vcore_hdsd_view.dart';
import '../one_door/views/vcore_one_door_view.dart';
import '../question/views/vcore_question_view.dart';

const kCacheKeyListDichVu = 'listDichVu.json';

class VcoreHomeServiceWidget extends StatefulHookWidget {
  const VcoreHomeServiceWidget({super.key});

  @override
  State<VcoreHomeServiceWidget> createState() => _VcoreHomeServiceWidgetState();
}

class _VcoreHomeServiceWidgetState extends State<VcoreHomeServiceWidget> {
  final ScrollController _controller = ScrollController();

  bool isLoading = true;
  List<BoxServiceModel> services = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    loadCacheService();

    Future.delayed(Duration.zero, () {
      loadService();
    });
  }

  //{phuoc} Thêm hàm sắp xếp lại dữ liệu theo hàng
  void sortServices(List<BoxServiceModel> services, int rows) {
    // Chỉ sắp xếp theo thứ tự ưu tiên, không cần logic phức tạp
    List<String> priority = [
      "XemThoiKhoaBieu",
      "DiemMonHoc",
      "TheSinhVien",
    ];

    services.sort((a, b) {
      int aIndex = priority.indexOf(a.loaiBoxDichVuEnum.toString());
      int bIndex = priority.indexOf(b.loaiBoxDichVuEnum.toString());

      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;

      return aIndex.compareTo(bIndex);
    });
  }
  loadCacheService() {
    VnuCacheFileManager().getCacheFile(kCacheKeyListDichVu).then(
      (data) {
        try {
          var dataString = data ?? '';
          if (dataString.isEmpty) {
            return;
          }
          var dataJson = jsonDecode(dataString) as List;
          List<BoxServiceModel> listObj = [];
          for (var element in dataJson) {
            try {
              BoxServiceModel? model;
              if (element is Map<String, dynamic>) {
                model = BoxServiceModel.fromJson(element);
              } else if (element is Map<dynamic, dynamic>) {
                model = BoxServiceModel.fromJson(element.toStringDynamic());
              }
              if (model != null) {
                if (model.loaiBoxDichVuEnum?.mapTypeBoxService() != HomeService.XemLichThi) {
                  listObj.add(model);
                }
              }
            } catch (e) {
              logError(e.toString());
            }
          }
          sortServices(listObj, 3);
          // Api gọi chưa xong thì update trước.
          if (services.isEmpty) {
            setState(() {
              services = listObj;
              isLoading = false;
            });
          }
        } catch (e) {
          logError(e.toString());
        }
      },
    );
  }

  loadService() async {
    try {
      var response = await ApiRepository().getBoxServices();
      response = response.where((element) => element.loaiBoxDichVuEnum?.mapTypeBoxService() != HomeService.XemLichThi).toList();
      print("DEBUG: Loaded ${response.length} services");
      for (var service in response) {
        print("DEBUG: Service - ${service.loaiBoxDichVuEnum} - ${service.tenBoxDichVu}");
      }
      sortServices(response, 3);
      setState(() {
        services = response;
        isLoading = false;
      });

      if (response.isNotEmpty) {
        try {
          var data = response.map((e) => e.toJson()).toList();
          VnuCacheFileManager()
              .saveCacheFile(kCacheKeyListDichVu, jsonEncode(data));
        } catch (e) {
          logError(e.toString());
        }
      } else {
        VnuCacheFileManager().deleteCacheFile(kCacheKeyListDichVu);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      logError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    //
    final marginLeft = useState(0.0);

    return Column(
      children: [
        SizedBox(
          //{phuoc} thay đổi chiều cao của scroll view
          height: 320,
          width: double.infinity,
          child: NotificationListener<ScrollUpdateNotification>(
            child: (isLoading && services.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _controller,
                    slivers: [
                      SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final BoxServiceModel? serviceModel =
                                services.elementAtOrNull(index);
                            final HomeService? service = serviceModel
                                ?.loaiBoxDichVuEnum
                                ?.mapTypeBoxService();
                            return InkWell(
                              onTap: () => _handleNaviService(service),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: serviceModel?.icon?.isNotEmpty ==
                                            true
                                        ? CachedNetworkImage(
                                            imageUrl: serviceModel!.icon!,
                                          )
                                        : svgAsset(
                                            'assets/images/${service?.icon}'),
                                  ),
                                  spaceHeight(4),
                                  Text(
                                    service?.title ?? '',
                                    style: TextStyles.regular
                                        .copyWith(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            );
                          },
                          childCount: services.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          //{phuoc} thay đổi số hàng của scroll view
                          crossAxisCount: 3,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 12,
                        ),
                      )
                    ],
                  ),
            onNotification: (notification) {
              double newMargin = (notification.metrics.pixels /
                      _controller.position.maxScrollExtent) *
                  (2.0 / 3.0) *
                  30.0;
              newMargin = max(0, newMargin);

              newMargin = min(newMargin, 20);
              marginLeft.value = newMargin;
              return true;
            },
          ),
        ),

        // Scroll indicator
        SizedBox(
          width: double.infinity,
          height: 20,
          child: Center(
            child: Stack(
              children: [
                Container(
                  height: 5,
                  width: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xffDDE3EE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  height: 5,
                  width: 10,
                  margin: EdgeInsets.only(left: marginLeft.value),
                  decoration: BoxDecoration(
                    color: const Color(0xff003392),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  _handleNaviService(HomeService? service) {
    switch (service) {
      case HomeService.BanDoSo:
        Get.to(() => const VcoreImmapView());
        break;
      case HomeService.CamNang:
        Get.to(() => const VcoreCamNangView());
        break;
      case HomeService.DangKyNoiTru:
        snackBarWarning('Chức năng đang hoàn thiện');
        //Get.to(() => const NtBoardingView());
        break;
      case HomeService.DiemMonHoc:
        Get.to(() => const VcoreCoursePointsView());
        break;
      case HomeService.HuongDanSuDung:
        Get.to(() => const VcoreHdsdView());
        break;
      case HomeService.MucHoiDap:
        Get.to(() => const VcoreQuestionView());
        break;
      case HomeService.ThuTucMotCua:
        Get.to(() => const VcoreOneDoorView());
        break;
      case HomeService.TimPhongTro:
        Get.to(() => const VcoreMotelView());
        break;
      case HomeService.XemLichThi:
        Get.to(() => const VcoreExamScheduleView());
        break;
      case HomeService.XemThoiKhoaBieu:
        Get.to(() => const VcoreExamScheduleView());
        break;
      case HomeService.PhanAnhHienTruong:
        Get.to(() => const VcorePahtView());
        break;
      // case HomeService.TheSinhVien:
      //   // snackBarWarning('Thẻ sinh viên');
      //   // Get.to(() => const VcoreStudentCardView());
      //   snackBarWarning('Chức năng đang hoàn thiện');
      //   break;
      default:
    }
  }
}
