
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'inmapz_platform_interface.dart';

class Inmapz {
  Future<String?> getPlatformVersion() {
    return InmapzPlatform.instance.getPlatformVersion();
  }
}

class IMSearchRouteInput {
  final int? fromID;
  final int? toID;

  IMSearchRouteInput(this.fromID, this.toID);
}

class IMSearchRouteByRefInput {
  final String? fromID;
  final String? toID;

  IMSearchRouteByRefInput(this.fromID, this.toID);
}

class IMLocatePOIInput {
  final int poiID;

  IMLocatePOIInput(this.poiID);
}

class IMLocatePOIByRefInput {
  final String poiID;

  IMLocatePOIByRefInput(this.poiID);
}

class IMZoomInput {
  final int zoom;
  IMZoomInput(this.zoom);
}

class IMKisokRefInput {
  final String kioskRef;
  IMKisokRefInput(this.kioskRef);
}

class IMFloorInput {
  final int floor;
  IMFloorInput(this.floor);
}

class IMCategoryFloorInput {
  final int floor;
  final int idCategory;
  IMCategoryFloorInput(this.idCategory, this.floor);
}

class IMRegionFloorInput {
  final int floor;
  final int idRegion;
  IMRegionFloorInput(this.idRegion, this.floor);
}

class IMTypeFloorInput {
  final int floor;
  final int idType;
  IMTypeFloorInput(this.idType, this.floor);
}

class IMCategoryFocusInput {
  final bool focus;
  final int idCategory;
  IMCategoryFocusInput(this.idCategory, this.focus);
}

class IMRegionFocusInput {
  final bool focus;
  final int idRegion;
  IMRegionFocusInput(this.idRegion, this.focus);
}

class IMTypeFocusInput {
  final bool focus;
  final int idType;
  IMTypeFocusInput(this.idType, this.focus);
}

class IMMapViewController {
  static final instance = IMMapViewController._();

  IMMapViewController._() {

  }

  final MethodChannel _channel = const MethodChannel('plugins.where.place/flutter_to_android');
  static const MethodChannel _channel2 = const MethodChannel('plugins.where.place/android_to_flutter');



  Future<void> searchRoute({required IMSearchRouteInput searchRouteInput}) {
    final Map<String, int?> args = <String, int?>{
      'from': searchRouteInput.fromID,
      'to': searchRouteInput.toID,
    };

    return _channel.invokeMethod('searchRoute', args);
  }

  Future<void> searchRouteByRef({required IMSearchRouteByRefInput searchRouteByRefInput}) {
    final Map<String, String?> args = <String, String?>{
      'from': searchRouteByRefInput.fromID,
      'to': searchRouteByRefInput.toID,
    };

    return _channel.invokeMethod('searchRouteByRef', args);
  }

  Future<void> locatePOI({required IMLocatePOIInput locatePOIInput}) {
    final Map<String, int> args = <String, int>{
      'poi': locatePOIInput.poiID,
    };

    return _channel.invokeMethod('locatePOI', args);
  }

  Future<void> closeRouteMode() {
    return _channel.invokeMethod('closeRouteMode', null);
  }

  Future<void> locatePOIByRef({required IMLocatePOIByRefInput locatePOIByRefInput}) {
    final Map<String, String> args = <String, String>{
      'poi': locatePOIByRefInput.poiID,
    };

    return _channel.invokeMethod('locatePOIByRef', args);
  }

  Future<double> getCurrentZoom() async {
    return await _channel.invokeMethod('getCurrentZoom', null);
  }

  Future<void> changeZoom({required IMZoomInput zoomInput}) {
    final Map<String, int> args = <String, int>{
      'zoom': zoomInput.zoom,
    };

    return _channel.invokeMethod('changeZoom', args);
  }

  Future<void> setVisibility(bool visibility) {
    final Map<String, int> args = <String, int>{
      'visibility': visibility ? 1 : 0,
    };

    return _channel.invokeMethod('setVisibility', args);
  }

  Future<bool> changeFloor({required IMFloorInput floorInput}) async  {
    final Map<String, int> args = <String, int>{
      'floor': floorInput.floor,
    };

    return await _channel.invokeMethod('changeFloor', args);
  }

  Future<String?> getCurrentLocation() {
    return _channel.invokeMethod('getCurrentLocation', null);
  }


  Future<String?> getListDataByCategory({required IMCategoryFloorInput categoryFloorInput}) {
    final Map<String, int> args = <String, int>{
      'idCategory': categoryFloorInput.idCategory,
      'floor': categoryFloorInput.floor
    };
    return _channel.invokeMethod('getListDataByCategory', args);
  }

  Future<String?> getListDataByRegion({required IMRegionFloorInput regionFloorInput}) {
    final Map<String, int> args = <String, int>{
      'idRegion': regionFloorInput.idRegion,
      'floor': regionFloorInput.floor
    };
    return _channel.invokeMethod('getListDataByRegion', args);
  }

  Future<String?> getListDataByType({required IMTypeFloorInput typeFloorInput}) {
    final Map<String, int> args = <String, int>{
      'idType': typeFloorInput.idType,
      'floor': typeFloorInput.floor
    };
    return _channel.invokeMethod('getListDataByType', args);
  }

  Future<void> setKioskIdByRef({required IMKisokRefInput kisokRefInput}) {
    final Map<String, String> args = <String, String>{
      'kioskRef': kisokRefInput.kioskRef,
    };

    return _channel.invokeMethod('setKioskIdByRef', args);
  }

  Future<bool> focusPoiByType({required IMTypeFocusInput typeFocusInput}) async {
    final Map<String, int> args = <String, int>{
      'idType': typeFocusInput.idType,
      'focus': typeFocusInput.focus ? 1 : 0
    };
    return await _channel.invokeMethod('focusPoiByType', args);
  }

  Future<bool> focusPoiByCategory({required IMCategoryFocusInput categoryFocusInput}) async {
    final Map<String, int> args = <String, int>{
      'idCategory': categoryFocusInput.idCategory,
      'focus': categoryFocusInput.focus ? 1 : 0
    };
    return await _channel.invokeMethod('focusPoiByCategory', args);
  }

  Future<bool> focusPoiByRegion({required IMRegionFocusInput regionFocusInput}) async {
    final Map<String, int> args = <String, int>{
      'idRegion': regionFocusInput.idRegion,
      'focus': regionFocusInput.focus ? 1 : 0
    };
    return await _channel.invokeMethod('focusPoiByRegion', args);
  }



  void setMethodCallHandler(AppCaller appCaller) {
    debugPrint("inmapz setMethodCallHandler ");
    _channel2.setMethodCallHandler((call) async {
      var method = call.method;
      debugPrint("call.method $method");

      if (call.method == "closeIndoorMap") {
        appCaller.closeIndoorMap();
        return "closeIndoorMap";
      }



      return "";
    });
  }

}

class IMMapView extends StatefulWidget {

  const IMMapView({
    this.language = 'vi',
    this.kioskRef = '',
  });

  final String language;

  final String kioskRef;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return IMMapViewState(language: language, kioskRef: kioskRef);
  }
}

class IMMapViewState extends State<IMMapView> implements AppCaller {
  final String language;
  final String kioskRef;
  IMMapViewState({
    this.language = 'vi',
    this.kioskRef = ''
  }) : super();

  @override
  void initState() {
    // TODO: implement initState
    // IMMapViewController.instance.setMethodCallHandler(this);
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    const String viewType = 'IMMapView';
    // Pass parameters to the platform side.

    Map<String, dynamic> creationParams = <String, dynamic>{

    };
    creationParams.putIfAbsent('language', () => this.language);
    creationParams.putIfAbsent('kioskRef', () => this.kioskRef);

    // TODO: implement build
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }

  @override
  void bottombar(bool isVisible) {
    // TODO: implement bottombar
  }

  @override
  void navToScreen(String name) {
    // TODO: implement navToScreen
  }

  @override
  void topbar(bool isVisible) {
    // TODO: implement topbar
  }

  @override
  void update() {
    // TODO: implement update
    debugPrint("update");
    setState(() {

    });
  }

  @override
  void updateCurrentFloor(int floor) {
    // TODO: implement updateCurrentFloor
  }

  @override
  void updateCurrentFloors(List<int> floors) {
    // TODO: implement updateCurrentFloors
  }

  @override
  void closeIndoorMap() {
    // TODO: implement closeIndoorMap
  }

}
