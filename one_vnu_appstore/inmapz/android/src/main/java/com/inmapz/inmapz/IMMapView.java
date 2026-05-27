package com.inmapz.inmapz;

import androidx.annotation.NonNull;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;
//import com.inmapz.dhy.fragments.InmapZMapController;

import com.inmapz.vnu.controllers.AndroidAndFlutterBridgeController;
import com.inmapz.vnu.controllers.InmapZMapController;
import com.inmapz.vnu.controllers.callbacks.AndroidToFlutterCallback;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import org.jetbrains.annotations.NotNull;
import place.where.common.MyLog;


public class IMMapView extends InmapZMapController implements PlatformView, MethodChannel.MethodCallHandler {

    private MethodChannel flutterToAndroid;
    private MethodChannel androidToFlutter;

    public IMMapView(BinaryMessenger binaryMessenger, FragmentActivity activity, int id, LifecycleOwner lifecycleOwner) {
        super(activity, id, lifecycleOwner);
        flutterToAndroid = new MethodChannel(binaryMessenger, "plugins.where.place/flutter_to_android");
        flutterToAndroid.setMethodCallHandler(this);
        androidToFlutter = new MethodChannel(binaryMessenger, "plugins.where.place/android_to_flutter");
        AndroidAndFlutterBridgeController.getController().setAndroidToFlutterCallback(new AndroidToFlutterCallback() {
            @Override
            public void closeIndoorMap() {
                androidToFlutter.invokeMethod("closeIndoorMap", null);
            }
        });
    }

    @Override
    public void onMethodCall(@NonNull @NotNull MethodCall call, @NonNull @NotNull MethodChannel.Result result) {
        switch (call.method) {
            case "searchRoute":
                break;
            case "searchRouteByRef":
                MyLog.m78d("searchRoute "+call.arguments);
                String fromRef = call.argument("from");
                String toRef = call.argument("to");
                directionBetweenPOIs(fromRef, toRef);
                break;
            case "locatePOI":
                int poi = call.argument("poi");
                locatePoi(poi);
                break;
            case "locatePOIByRef":
                String poiRef = call.argument("poi");
                locatePoi(poiRef);
                break;
            case "setVisibility":
                int visibility = call.argument("visibility");
                setVisibility(visibility  > 0 ? true : false);
                break;
        }
    }

    @Override
    public void dispose() {

        if (disposed) {
            return;
        }

        onDestroy(lifecycleOwner);


        flutterToAndroid.setMethodCallHandler(null);
        Lifecycle lifecycle = lifecycleOwner.getLifecycle();
        if (lifecycle != null) {
            lifecycle.removeObserver(this);
        }

        disposed = true;
    }
}
