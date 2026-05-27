package com.inmapz.inmapz;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentActivity;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import org.jetbrains.annotations.NotNull;
import where.place.poc.language.Functions;
import where.place.poc.log.MyLog;

import java.lang.ref.WeakReference;
import java.util.Map;

public class IMMapViewFactory extends PlatformViewFactory {
    /**
     * @param createArgsCodec the codec used to decode the args parameter of {@link #create}.
     */

    private final BinaryMessenger binaryMessenger;
    WeakReference<FragmentActivity> activity;
    public IMMapViewFactory(BinaryMessenger binaryMessenger, WeakReference<FragmentActivity> activity) {
        super(StandardMessageCodec.INSTANCE);
        this.activity = activity;
        this.binaryMessenger = binaryMessenger;
    }

    @NonNull
    @NotNull
    @Override
    public PlatformView create(Context context, int viewId, @Nullable @org.jetbrains.annotations.Nullable Object args) {
        MyLog.m78d("context "+context.getClass().getName());
        String kioskRef = "";
        try {
            Map<String, Object> creationParams = (Map<String, Object>) args;
            if (creationParams.containsKey("language")) {
                String lan = (String) creationParams.get("language");
                Functions.setLanguage(activity.get(), lan);
            }
            if (creationParams.containsKey("kioskRef")) {
                kioskRef = (String) creationParams.get("kioskRef");
            }

        } catch (Exception e) {
            MyLog.m78d("create "+e.getMessage());
        }
        IMMapView imMapView = new IMMapView(binaryMessenger, activity.get(), viewId, activity.get());
//        imMapView.setKioskIdByRef(kioskRef);
        return imMapView;
    }
}
