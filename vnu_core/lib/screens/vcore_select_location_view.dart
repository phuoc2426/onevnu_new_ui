import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/themes/app_theme.dart';
// import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreSelectLocationController extends GetxController {
  BuildContext? context;
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  CameraPosition kGooglePlex = const CameraPosition(
    target: LatLng(21.0388688, 105.783268),
    zoom: 16.2,
  );

  RxList<Marker> markers = RxList<Marker>([]);

  //Value select
  LatLng dropPoint = LatLng(21.0388688, 105.783268);

  RxBool isMoveCamera = false.obs;

  //Private variable
  bool _isCompleteController = false;

  bool isEditLocation = false;

  configEditLocation(LatLng location) {
    isEditLocation = true;
    dropPoint = location;

    kGooglePlex = CameraPosition(target: location, zoom: 16.2);
  }

  completeWithMapController(GoogleMapController controller) {
    if (_isCompleteController) return;

    mapController.complete(controller);
    _isCompleteController = true;
    gotoCurrentLocation();
  }

  gotoCurrentLocation() async {
    if (isEditLocation) {
      final GoogleMapController controller = await mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: dropPoint, zoom: 16),
        ),
      );

      return;
    }
    try {
      var location = await _determinePosition();
      var latLong = LatLng(location.latitude, location.longitude);

      final GoogleMapController controller = await mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLong, zoom: 16),
        ),
      );

      //Update new droppoint if need
      dropPoint = latLong;
    } catch (e) {}
  }

  _buildMarker() {}

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
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}

class VcoreSelectLocationView extends GetView<VcoreSelectLocationController> {
  final LatLng? selectedLocation;
  const VcoreSelectLocationView({super.key, this.selectedLocation});
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreSelectLocationController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        if (selectedLocation != null && controller.isEditLocation == false) {
          controller.configEditLocation(selectedLocation!);
        }
        return VcoreModuleScaffold(
          title: 'Chọn vị trí địa điểm',
          actions: [
            IconButton(
              onPressed: () {
                Get.back(result: controller.dropPoint);
              },
              color: Colors.green,
              icon: const Icon(Icons.done_all, size: 28),
            ),
          ],
          body: ProgressHubWidget(
            child: Obx(
              () => Stack(
                fit: StackFit.expand,
                alignment: AlignmentDirectional.center,
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: controller.kGooglePlex,
                    onMapCreated: (GoogleMapController mapController) async {
                      controller.completeWithMapController(mapController);
                    },
                    myLocationEnabled: true,
                    compassEnabled: true,
                    markers: Set<Marker>.of(controller.markers),
                    onCameraMoveStarted: () {
                      controller.isMoveCamera.value = true;
                    },
                    onCameraIdle: () {
                      controller.isMoveCamera.value = false;
                    },
                    onCameraMove: (position) {
                      controller.dropPoint = position.target;
                    },
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 60,
                          color: AppTheme.backgroundBlueColor,
                        ),
                        spaceHeight(45),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
