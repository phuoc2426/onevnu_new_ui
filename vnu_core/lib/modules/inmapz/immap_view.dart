import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class IMMapView extends StatelessWidget {
  const IMMapView({
    this.language = 'vi',
  });

  final String language;

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'plugins.where.place/immap_view';

    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'language': language
    };

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class IMSearchRouteInput {
  final String? fromID;
  final String? toID;

  IMSearchRouteInput(this.fromID, this.toID);
}

class IMLocatePOIInput {
  final String poiID;

  IMLocatePOIInput(this.poiID);
}

abstract class IMMapViewControllerDelegate {
  void closeMapView();
}

class IMMapViewController {
  IMMapViewControllerDelegate? _delegate = null;

  IMMapViewController() {
    _channel.setMethodCallHandler(myUtilsHandler);
  }

  void setDelegate(IMMapViewControllerDelegate delegate) {
    this._delegate = delegate;
  }

  final MethodChannel _channel =
      const MethodChannel('plugins.where.place/immap_view_channel');

  Future<void> searchRoute({required IMSearchRouteInput searchRouteInput}) {
    final Map<String, String?> args = <String, String?>{
      'from': searchRouteInput.fromID,
      'to': searchRouteInput.toID,
    };

    return _channel.invokeMethod('searchRoute', args);
  }

  Future<void> locatePOI({required IMLocatePOIInput locatePOIInput}) {
    final Map<String, String> args = <String, String>{
      'poi': locatePOIInput.poiID,
    };

    return _channel.invokeMethod('locatePOI', args);
  }

  Future<dynamic> myUtilsHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'willCloseMap':
        return _delegate?.closeMapView();
      default:
        throw MissingPluginException('notImplemented');
    }
  }
}
