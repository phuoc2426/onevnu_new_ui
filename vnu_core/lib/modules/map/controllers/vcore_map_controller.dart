import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/marker_icon_generator.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/info_window.dart';

import '../../../models/model.dart';

class VcoreMapController extends GetxController {
  BuildContext? context;

  RxList<KhuVucBanDoModel> listKhuVuc = RxList([]);
  Rxn<KhuVucBanDoModel> currentKhuVuc = Rxn();

  RxList<LoaiDiaDiemBanDoModel> listLoaiDiaDiem = RxList([]);
  Rxn<LoaiDiaDiemBanDoModel> currentLoaiDiaDiem = Rxn();

  RxList<DiaDiemBanDoModel> listAllDiaDiemBanDo = RxList([]);
  RxList<DiaDiemBanDoModel> listDiaDiemBanDo = RxList([]);

  int pageIndex = 1;
  int pageSize = 9999;
  var isLoadMoreEnable = true;

  //MAp control
  late GoogleMapController googleMapController;
  final double defaultZoom = 18;
  int mapzoom = 18;
  MapType mapType = MapType.normal;
  final CustomInfoWindowController customInfoWindowController =
      CustomInfoWindowController();

  Set<Marker> markers = {};

  //
  final TextEditingController textEditingController = TextEditingController();

  DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();
  double initialDragChildSize = 0.0;

  @override
  void onInit() {
    super.onInit();

    getTatCaLoaiDiaDiem();

    getTatKhuVucBanDo();

    try {
      _determinePosition();
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void dispose() {
    googleMapController.dispose();
    textEditingController.dispose();
    draggableScrollableController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  //
  getTatKhuVucBanDo() async {
    try {
      var response = await ApiRepository().getTatKhuVucBanDo();
      listKhuVuc.addAll(response);
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  getTatCaLoaiDiaDiem() async {
    try {
      var response = await ApiRepository().getTatLoaiDiaDiemBanDo();
      listLoaiDiaDiem.addAll(response);
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  changeKhuVuc(KhuVucBanDoModel? khuVuc) {
    currentKhuVuc.value = khuVuc;
    excSearchAndFilterKhuVuc();
  }

  excSearchAndFilterKhuVuc() {
    //
    List<DiaDiemBanDoModel> newListBanDo = listAllDiaDiemBanDo;
    if (currentKhuVuc.value == null) {
      newListBanDo = listAllDiaDiemBanDo;
    } else {
      newListBanDo = listAllDiaDiemBanDo
          .where((e) => e.guidKhuVucBanDo == currentKhuVuc.value?.guid)
          .toList();
    }

    if (currentLoaiDiaDiem.value != null) {
      newListBanDo = listAllDiaDiemBanDo
          .where(
              (e) => e.guidLoaiDiaDiemBanDo == currentLoaiDiaDiem.value?.guid)
          .toList();
    }

    if (textEditingController.text.trim().isNotEmpty) {
      //Search title
      newListBanDo = newListBanDo.where((e) {
        //Search like
        return e.tenDiaDiem?.toKhongDau().contains(
                currentLoaiDiaDiem.value?.tenLoaiDiaDiemBanDo ??
                    '****___****####') ??
            false;
      }).toList();
    }

    if (newListBanDo.isEmpty) {
      snackBarWarning('Không tìm thấy địa điểm phù hợp.');
    }

    listDiaDiemBanDo.value = newListBanDo;

    buildMaker();
  }

  buildMaker({double? zoom}) async {
    markers.removeWhere((element) => true);
    markers = {};

    Set<Marker> newMarkers = {};
    for (DiaDiemBanDoModel item in listDiaDiemBanDo) {
      // ICon
      IconData iconData =
          IconData(('0xf33c').parseImageInt(), fontFamily: 'MaterialIcons');

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
      List<String> latlongList = (item.kinhDoViDo ?? ',').split(',');
      LatLng _latLng = LatLng(double.parse(latlongList.first.trim()),
          double.parse(latlongList.last.trim()));
      logSuccess(latlongList.toString());

      //Marker
      newMarkers.add(Marker(
          markerId: MarkerId(item.guid.toString()),
          position: _latLng,
          icon: marker,
          //infoWindow: InfoWindow(title: item.tieuDe),
          onTap: () {
            customInfoWindowController.addInfoWindow!(
                InfoWindowWidget(
                  diaDiemBanDoSo: DiaDiemBanDoSo(
                      tieuDe: item.tenDiaDiem, toaDo: item.kinhDoViDo),
                ),
                _latLng);
          }));
      //Marker title
      if (zoom == null || zoom > 16) {
        BitmapDescriptor markerText = await MarkerGenerator(100)
            .createBitmapDescriptorFromString(item.tenDiaDiem ?? '',
                textStyle: AppTheme.headline4.copyWith(
                    color: mapType == MapType.satellite
                        ? Colors.grey[200]
                        : Colors.black));
        newMarkers.add(Marker(
            markerId: MarkerId('label_${item.guid.toString()}'),
            position: _latLng,
            anchor: const Offset(0.5, 0.0),
            icon: markerText,
            onTap: () {}));
      }
    }

    markers = newMarkers;

    update();
  }

  refreshData() {
    pageIndex = 1;
    _loadData();
  }

  loadMoreData() {
    pageIndex += 1;
    _loadData();
  }

  _loadData() async {
    try {
      Utils.showProgress(context);
      final Map<String, dynamic> queries = {
        'pageIndex': pageIndex,
        'pageSize': pageSize,
        'sort': 'created,desc',
        'keyword': ''
      };

      for (var khuVuc in listKhuVuc) {
        queries.addIf(khuVuc.guid != null && khuVuc.guid!.isNotEmpty,
            'guidKhuVucs', khuVuc.guid ?? '');
      }

      for (var loaiDiaDiem in listLoaiDiaDiem) {
        queries.addIf(loaiDiaDiem.guid != null && loaiDiaDiem.guid!.isNotEmpty,
            'guidLoaiDiaDiems', loaiDiaDiem.guid ?? '');
      }

      var response = await ApiRepository().getDiaDiemBanDo(queries);
      if (pageIndex == 1) {
        listAllDiaDiemBanDo.value = response.data ?? [];
      } else {
        listAllDiaDiemBanDo.addAll(response.data ?? []);
      }
      excSearchAndFilterKhuVuc();
      Utils.dismissProgress(context);
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }
}
