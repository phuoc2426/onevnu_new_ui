package com.inmapz.inmapz;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** InmapzPlugin */
import androidx.annotation.NonNull;

import androidx.fragment.app.FragmentActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import org.jetbrains.annotations.NotNull;

import java.lang.ref.WeakReference;

/** InmapzPlugin */
public class InmapzPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private WeakReference<FragmentActivity> cachedActivity;

  private FlutterPluginBinding flutterPluginBinding;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding;
    if (flutterPluginBinding != null && cachedActivity != null)
      flutterPluginBinding
              .getPlatformViewRegistry()
              .registerViewFactory("IMMapView", new IMMapViewFactory(flutterPluginBinding.getBinaryMessenger(), cachedActivity));
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

  }

  @Override
  public void onAttachedToActivity(@NonNull @NotNull ActivityPluginBinding binding) {
    cachedActivity = new WeakReference<>((FragmentActivity) binding.getActivity());
    if (flutterPluginBinding != null && cachedActivity != null)
      flutterPluginBinding
              .getPlatformViewRegistry()
              .registerViewFactory("IMMapView", new IMMapViewFactory(flutterPluginBinding.getBinaryMessenger(), cachedActivity));
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull @NotNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    cachedActivity.clear();
    cachedActivity = null;
  }
}
