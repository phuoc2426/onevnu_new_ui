import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/map_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/dia_diem_ban_do_model.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/map/controllers/vcore_map_controller.dart';
import 'package:vnu_core/modules/map/views/vcore_map_filter_widget.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/button_icon_widger.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

class VcoreMapView extends GetView<VcoreMapController> {
  const VcoreMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreMapController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listAllDiaDiemBanDo.isEmpty) {
              controller.refreshData();
            }
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Bản đồ số',
              // leftAction: IconButton(
              //     onPressed: () {
              //       globalEvent.fire(OpenMenuEvent());
              //     },
              //     icon: const Icon(Icons.menu)),
              rightActions: [
                // InkWell(
                //   onTap: () {
                //     Get.to(() => const VcoreImmapView());
                //   },
                //   child: Padding(
                //     padding: const EdgeInsets.only(right: 10),
                //     child: svgAsset('assets/images/logo-inmapz.svg',
                //         height: 30, color: Colors.white),
                //   ),
                // ),
                IconButton(
                    onPressed: () {
                      //_mapCubit.getDanhSachBanDoSo();
                    },
                    icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
            backgroundColor: Colors.white,
            body: Container(
              child: Obx(
                () => Stack(
                  children: [
                    Stack(
                      children: [
                        // Maps
                        Container(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                    zoom: controller.defaultZoom,
                                    target:
                                        const LatLng(21.0388688, 105.783268)),
                                markers: controller.markers,
                                mapType: controller.mapType,
                                mapToolbarEnabled: true,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                onMapCreated: (ggController) {
                                  controller.googleMapController = ggController;
                                  logInfo(mapStyle.toString());
                                  controller.googleMapController.setMapStyle(
                                      '[{"featureType": "poi","stylers": [{"visibility": "off"}]}]');
                                  controller.customInfoWindowController
                                      .googleMapController = ggController;
                                },
                                onTap: (position) {
                                  controller.customInfoWindowController
                                      .hideInfoWindow!();
                                },
                                onCameraMove: ((position) {
                                  logInfo(position.zoom.toString());
                                  controller.customInfoWindowController
                                      .onCameraMove!();
                                  // _debouncer.run(() {
                                  if ("${position.zoom.toInt()}" !=
                                      "$controller.mapzoom") {
                                    controller.mapzoom = position.zoom.toInt();
                                    // logSuccess("Render marker with zoom.....");
                                    // controller.buildMaker(zoom: position.zoom);
                                  }
                                  // });
                                }),
                              ),
                              CustomInfoWindow(
                                controller:
                                    controller.customInfoWindowController,
                                height: 60,
                                width: 150,
                                offset: 50,
                              ),
                              Positioned(
                                  left: 10,
                                  bottom: 30,
                                  child: InkWell(
                                    onTap: () {
                                      controller.mapType =
                                          controller.mapType == MapType.normal
                                              ? MapType.satellite
                                              : MapType.normal;
                                      controller.update();
                                    },
                                    child: SizedBox(
                                      height: 48,
                                      width: 48,
                                      child: Image.asset(
                                        controller.mapType == MapType.normal
                                            ? 'assets/images/ic_map_satellite.png'
                                            : 'assets/images/ic_map_default.png',
                                        package: kPackageName,
                                      ),
                                    ),
                                  )),
                              Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: _searchAndCategoryWidget(
                                      controller, context)),
                            ],
                          ),
                        ),

                        // Khu vuc
                        controller.listDiaDiemBanDo.isNotEmpty
                            ? _listResult(controller)
                            : spaceHeight(0),

                        // Container(
                        //   height: 100,
                        //   width: 200,
                        //   child: Text(
                        //     'Adjaldjlsajdl',
                        //     style: TextStyles.regular.copyWith(color: Colors.red),
                        //   ),
                        // ),
                      ],
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

  Widget _searchAndCategoryWidget(
      VcoreMapController controller, BuildContext context) {
    const normalColor = Color(0xff637392);
    const activeColor = Color(0xff003392);

    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300)),
            child: TextField(
              onChanged: ((value) {
                // _debouncer.run(() {
                //   logInfo(value);
                //   _buildDanhSachDiaDiem();
                // });
              }),
              onSubmitted: (value) {
                controller.excSearchAndFilterKhuVuc();
              },
              maxLines: 1,
              controller: controller.textEditingController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                isDense: true,
                hintText: 'Tìm kiếm',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        controller.textEditingController.clear();
                        controller.excSearchAndFilterKhuVuc();
                      },
                      child: const Icon(Icons.clear),
                    ),
                    svgAction(
                      'assets/images/ic_filter.svg',
                      color: controller.currentKhuVuc.value != null
                          ? activeColor
                          : normalColor,
                      action: () {
                        showFilterPopup(controller, context);
                      },
                    )
                  ],
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 40),
                hintStyle: AppTheme.body2,
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                border: const UnderlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.listLoaiDiaDiem.length,
                itemBuilder: (context, index) {
                  LoaiDiaDiemBanDoModel loaiBanDoSo =
                      controller.listLoaiDiaDiem[index];
                  bool isSelected = controller.currentLoaiDiaDiem.value?.guid ==
                      loaiBanDoSo.guid;
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 0.0, right: 8, top: 10),
                    child: ButtonIconWidget(
                      title: loaiBanDoSo.tenLoaiDiaDiemBanDo ?? '',
                      iconCode: '0xf33c',
                      textColor: Colors.black,
                      bgColor: Colors.white,
                      borderColor:
                          isSelected ? const Color(0xffFB8500) : Colors.white,
                      action: () {
                        controller.currentLoaiDiaDiem.value =
                            isSelected ? null : loaiBanDoSo;
                        controller.excSearchAndFilterKhuVuc();
                        controller.update();
                        // bool selected = !loaiBanDoSo.isSelected;
                        // banDoSo?.resetSelected();
                        // loaiBanDoSo.isSelected = selected;
                        // _buildDanhSachDiaDiem();
                        // _searchStreamController.add(true);
                      },
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _listResult(VcoreMapController controller) {
    return LayoutBuilder(
      builder: (context, safeAreaSize) {
        controller.initialDragChildSize = 80 / safeAreaSize.maxHeight;
        return DraggableScrollableSheet(
          // expand: true,
          initialChildSize: controller.initialDragChildSize,
          maxChildSize: 0.8,
          minChildSize: controller.initialDragChildSize,
          controller: controller.draggableScrollableController,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(Icons.horizontal_rule_rounded),
                          Text(
                              'Danh sách địa điểm (${controller.listDiaDiemBanDo.length})')
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.listDiaDiemBanDo.length,
                      itemBuilder: ((context, index) {
                        DiaDiemBanDoModel diadiem =
                            controller.listDiaDiemBanDo[index];
                        return InkWell(
                          onTap: () {
                            controller.draggableScrollableController
                                .jumpTo(controller.initialDragChildSize);
                            scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.ease,
                            );
                            //Get marker
                            Marker _marker = controller.markers.firstWhere(
                              (element) =>
                                  element.markerId ==
                                  MarkerId(
                                    diadiem.guid.toString(),
                                  ),
                            );

                            controller.googleMapController.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                  _marker.position, controller.defaultZoom),
                            );
                            controller.googleMapController.showMarkerInfoWindow(
                              MarkerId(
                                diadiem.guid.toString(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            //height: 50,
                            child: Row(
                              children: [
                                Icon(
                                    IconData(('0xf33c').parseImageInt(),
                                        fontFamily: 'MaterialIcons'),
                                    size: 30,
                                    color: AppTheme.colorMain),
                                const SizedBox(
                                  width: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      diadiem.tenDiaDiem ?? '',
                                      style: AppTheme.body2.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    // Visibility(
                                    //   visible: (diadiem.moTa ?? '').isNotEmpty,
                                    //   child: const SizedBox(
                                    //     height: 4,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  showFilterPopup(VcoreMapController controller, BuildContext context) {
    // Get.to(
    //   () => VcoreMapFilterWidget(
    //     listKhuVuc: controller.listKhuVuc,
    //     onChangeKhuVuc: (khuVuc) {
    //       controller.changeKhuVuc(khuVuc);
    //     },
    //   ),
    // );
    //
    // logWarning('Filter popup');
    showDialog(
        context: context,
        builder: (ctx) {
          return Dialog(
            child: VcoreMapFilterWidget(
              listKhuVuc: controller.listKhuVuc,
              currentKhuVuc: controller.currentKhuVuc.value,
              onChangeKhuVuc: (khuVuc) {
                controller.changeKhuVuc(khuVuc);
              },
            ),
          );
        });
  }
}
