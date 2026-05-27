import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/debouncer.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/map_utils.dart';
import 'package:vnu_core/common/marker_icon_generator.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/cubit/map_cubit.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/extensions/iterables.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/button_icon_widger.dart';
import 'package:vnu_core/widgets/error_widget.dart';
import 'package:vnu_core/widgets/info_window.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:custom_info_window/custom_info_window.dart';

class VCoreMapsScreen extends StatefulWidget {
  const VCoreMapsScreen({super.key});

  @override
  State<VCoreMapsScreen> createState() => _VCoreMapsScreenState();
}

class _VCoreMapsScreenState extends State<VCoreMapsScreen> {
  //
  final MapCubit _mapCubit = MapCubit();
  final StreamController _mapStreamController = StreamController.broadcast();
  late GoogleMapController googleMapController;
  final double defaultZoom = 18;
  int mapzoom = 18;
  MapType mapType = MapType.normal;
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  //
  final TextEditingController _textEditingController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  final StreamController _searchStreamController = StreamController.broadcast();
  final StreamController _googleMapController = StreamController.broadcast();

  Set<Marker> _markers = {};

  BanDoSoModel? banDoSo;
  List<DiaDiemBanDoSo> danhSachDiaDiem = [];
  DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();
  double initialDragChildSize = 0.0;

  @override
  void initState() {
    super.initState();
    _getDanhSachBanDoSo();
    _getLocationPermision();
  }

  _getLocationPermision() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();
    if (status == PermissionStatus.granted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mapCubit.close();
    _mapStreamController.close();
    _customInfoWindowController.dispose();

    super.dispose();
  }

  _getDanhSachBanDoSo() {
    _mapCubit.getDanhSachBanDoSo();
  }

  _buildDanhSachDiaDiem() async {
    danhSachDiaDiem = [];
    DsCacLoaiBanDoSo? banDoDuocChon =
        (banDoSo?.dsCacLoaiBanDoSo ?? []).firstWhereOrNull((e) => e.isSelected);
    if (banDoDuocChon != null) {
      danhSachDiaDiem = banDoDuocChon.diaDiem ?? [];
    } else {
      // Tất cả bản đồ
      for (DsCacLoaiBanDoSo item in (banDoSo?.dsCacLoaiBanDoSo ?? [])) {
        danhSachDiaDiem.addAll(item.diaDiem ?? []);
      }
    }

    if (_textEditingController.text.trim().isNotEmpty) {
      danhSachDiaDiem = danhSachDiaDiem.where((element) {
        return element.tieuDe?.toKhongDau().toLowerCase().contains(
                _textEditingController.text
                    .trim()
                    .toKhongDau()
                    .toLowerCase()) ??
            false;
      }).toList();
    }
    await _buildMaker();
    //MORE MOVE TO FIRST ITEM
    //Animate to first marker
    if (_markers.isNotEmpty) {
      Marker _marker = _markers.first;

      googleMapController.animateCamera(
          CameraUpdate.newLatLngZoom(_marker.position, defaultZoom));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Bản đồ số',
        // leftAction: IconButton(
        //     onPressed: () {
        //       globalEvent.fire(OpenMenuEvent());
        //     },
        //     icon: const Icon(Icons.menu)),
        rightActions: [
          IconButton(
              onPressed: () {
                _mapCubit.getDanhSachBanDoSo();
              },
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      backgroundColor: Colors.white,
      body: BlocBuilder<MapCubit, MapState>(
        bloc: _mapCubit,
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(
              child: LoadingIndicator(),
            );
          }
          if (state is MapError) {
            return ErrorRefreshWidget(
              message: state.message,
              refreshAction: () {
                _getDanhSachBanDoSo();
              },
            );
          }

          if (state is MapLoadedSuccess) {
            logSuccess('successs');
            banDoSo = state.banDoSo;

            if (banDoSo?.isActive() == false) {
              return const Center(
                child: Text(
                  'Chức năng đang được cập nhật',
                  style: AppTheme.body2,
                ),
              );
            }

            _buildDanhSachDiaDiem();
          }
          return Stack(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: StreamBuilder<dynamic>(
                        stream: _mapStreamController.stream,
                        builder: (context, snapshot) {
                          return Stack(
                            children: [
                              StreamBuilder<dynamic>(
                                  stream: _googleMapController.stream,
                                  builder: (context, snapshot) {
                                    return GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                          zoom: defaultZoom,
                                          target: banDoSo?.defaultLocation() ??
                                              const LatLng(
                                                  21.0388688, 105.783268)),
                                      markers: _markers,
                                      mapType: mapType,
                                      mapToolbarEnabled: true,
                                      myLocationEnabled: true,
                                      myLocationButtonEnabled: true,
                                      onMapCreated: (controller) {
                                        googleMapController = controller;
                                        logInfo(mapStyle.toString());
                                        googleMapController.setMapStyle(
                                            '[{"featureType": "poi","stylers": [{"visibility": "off"}]}]');
                                        _customInfoWindowController
                                            .googleMapController = controller;
                                      },
                                      onTap: (position) {
                                        _customInfoWindowController
                                            .hideInfoWindow!();
                                      },
                                      onCameraMove: ((position) {
                                        logInfo(position.zoom.toString());
                                        _customInfoWindowController
                                            .onCameraMove!();
                                        // _debouncer.run(() {
                                        if ("${position.zoom.toInt()}" !=
                                            "$mapzoom") {
                                          mapzoom = position.zoom.toInt();
                                          logSuccess(
                                              "Render marker with zoom.....");
                                          _buildMaker(zoom: position.zoom);
                                        }
                                        // });
                                      }),
                                    );
                                  }),
                              CustomInfoWindow(
                                controller: _customInfoWindowController,
                                height: 60,
                                width: 150,
                                offset: 50,
                              ),
                              Positioned(
                                  left: 10,
                                  bottom: 30,
                                  child: InkWell(
                                    onTap: () {
                                      mapType = mapType == MapType.normal
                                          ? MapType.satellite
                                          : MapType.normal;
                                      _googleMapController.add(mapType);
                                    },
                                    child: StreamBuilder<dynamic>(
                                        stream: _googleMapController.stream,
                                        builder: (context, snapshot) {
                                          return SizedBox(
                                            height: 48,
                                            width: 48,
                                            child: Image.asset(
                                              mapType == MapType.normal
                                                  ? 'assets/images/ic_map_satellite.png'
                                                  : 'assets/images/ic_map_default.png',
                                              package: kPackageName,
                                            ),
                                          );
                                        }),
                                  )),
                              Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: _searchAndCategoryWidget()),
                            ],
                          );
                        }),
                  ),
                  _listResult(),
                ],
              ),
              // List
              // Positioned(bottom: 0, left: 0, right: 0, child: _listResult())
            ],
          );
        },
      ),
    );
  }

  Widget _searchAndCategoryWidget() {
    return Container(
      // height: 150,
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
                _debouncer.run(() {
                  logInfo(value);
                  _buildDanhSachDiaDiem();
                });
              }),
              maxLines: 1,
              controller: _textEditingController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                isDense: true,
                hintText: 'Tìm kiếm',
                suffixIcon: InkWell(
                  onTap: () {
                    _textEditingController.clear();
                    _buildDanhSachDiaDiem();
                  },
                  child: const Icon(Icons.clear),
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
            child: StreamBuilder<dynamic>(
                stream: _searchStreamController.stream,
                builder: (context, snapshot) {
                  return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (banDoSo?.dsCacLoaiBanDoSo ?? []).length,
                      itemBuilder: (context, index) {
                        DsCacLoaiBanDoSo loaiBanDoSo =
                            banDoSo!.dsCacLoaiBanDoSo![index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 0.0, right: 8, top: 10),
                          child: ButtonIconWidget(
                            title: loaiBanDoSo.tieuDe ?? '',
                            iconCode: loaiBanDoSo.isSelected
                                ? '0xf636'
                                : (loaiBanDoSo.maIcon ?? ''),
                            action: () {
                              bool selected = !loaiBanDoSo.isSelected;
                              banDoSo?.resetSelected();
                              loaiBanDoSo.isSelected = selected;
                              _buildDanhSachDiaDiem();
                              _searchStreamController.add(true);
                            },
                          ),
                        );
                      });
                }),
          ),
        ],
      ),
    );
  }

  Widget _listResult() {
    return LayoutBuilder(builder: (context, safeAreaSize) {
      initialDragChildSize = 60 / safeAreaSize.maxHeight;
      return DraggableScrollableSheet(
          // expand: true,
          initialChildSize: initialDragChildSize,
          maxChildSize: 0.8,
          minChildSize: initialDragChildSize,
          controller: draggableScrollableController,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        height: 60,
                        child: Column(
                          children: const [
                            Icon(Icons.horizontal_rule_rounded),
                            Text('Danh sách địa điểm')
                          ],
                        ),
                      ),
                      StreamBuilder<dynamic>(
                          stream: _mapStreamController.stream,
                          builder: (context, snapshot) {
                            return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: danhSachDiaDiem.length,
                                itemBuilder: ((context, index) {
                                  DiaDiemBanDoSo diadiem =
                                      danhSachDiaDiem[index];
                                  return InkWell(
                                    onTap: () {
                                      draggableScrollableController
                                          .jumpTo(initialDragChildSize);
                                      controller.animateTo(0,
                                          duration:
                                              const Duration(milliseconds: 250),
                                          curve: Curves.ease);
                                      //Get marker
                                      Marker _marker = _markers.firstWhere(
                                          (element) =>
                                              element.markerId ==
                                              MarkerId(diadiem.id.toString()));

                                      googleMapController.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                              _marker.position, defaultZoom));
                                      googleMapController.showMarkerInfoWindow(
                                          MarkerId(diadiem.id.toString()));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      //height: 50,
                                      child: Row(
                                        children: [
                                          Icon(
                                              IconData(
                                                  (diadiem.maIcon ?? '')
                                                      .parseImageInt(),
                                                  fontFamily: 'MaterialIcons'),
                                              size: 30,
                                              color: AppTheme.colorMain),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                diadiem.tieuDe ?? '',
                                                style: AppTheme.body2.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Visibility(
                                                visible: (diadiem.moTa ?? '')
                                                    .isNotEmpty,
                                                child: const SizedBox(
                                                  height: 4,
                                                ),
                                              ),
                                              //Mô tả
                                              Visibility(
                                                visible: (diadiem.moTa ?? '')
                                                    .isNotEmpty,
                                                child: Text(
                                                  diadiem.moTa ?? '',
                                                  style:
                                                      AppTheme.body2.copyWith(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }));
                          })
                    ],
                  )),
            );
          });
    });
  }

  _buildMaker({double? zoom}) async {
    _markers.removeWhere((element) => true);
    _markers = {};
    for (DiaDiemBanDoSo item in danhSachDiaDiem) {
      // ICon
      IconData iconData = IconData((item.maIcon ?? '').parseImageInt(),
          fontFamily: 'MaterialIcons');

      BitmapDescriptor marker;
      if (zoom == null || zoom > 16) {
        marker = await MarkerGenerator(100).createBitmapDescriptorFromIconData(
            iconData, AppTheme.white, AppTheme.white, AppTheme.colorMain);
      } else {
        marker = await MarkerGenerator(50).createBitmapDescriptorFromIconData(
            iconData, AppTheme.white, AppTheme.white, AppTheme.colorMain,
            isShowArrow: false);
      }

      //Location
      List<String> latlongList = (item.toaDo ?? ',').split(',');
      LatLng _latLng = LatLng(double.parse(latlongList.first.trim()),
          double.parse(latlongList.last.trim()));
      logSuccess(latlongList.toString());

      //Marker
      _markers.add(Marker(
          markerId: MarkerId(item.id.toString()),
          position: _latLng,
          icon: marker,
          //infoWindow: InfoWindow(title: item.tieuDe),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
                InfoWindowWidget(
                  diaDiemBanDoSo: item,
                ),
                _latLng);
          }));
      //Marker title
      if (zoom == null || zoom > 16) {
        BitmapDescriptor markerText = await MarkerGenerator(100)
            .createBitmapDescriptorFromString(item.tieuDe ?? '',
                textStyle: AppTheme.headline4.copyWith(
                    color: mapType == MapType.satellite
                        ? Colors.grey[200]
                        : Colors.black));
        _markers.add(Marker(
            markerId: MarkerId('label_${item.id.toString()}'),
            position: _latLng,
            anchor: const Offset(0.5, 0.0),
            icon: markerText,
            onTap: () {}));
      }
    }
    _mapStreamController.add(true);
  }
}
