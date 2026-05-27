# ============================================
# CRITICAL: Android 14/15 SDK 35 DEX Loading
# ============================================
# Keep all classes needed for proper DEX loading on Android 14/15
-keep class dalvik.** { *; }
-keep class libcore.** { *; }
-dontwarn dalvik.**
-dontwarn libcore.**

# Keep Application and Context classes
-keep public class * extends android.app.Application
-keep public class * extends android.content.Context

# Keep all constructors
-keepclassmembers class * {
    public <init>(...);
}

# ============================================
# Flutter & Dart
# ============================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.app.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Retrofit & OkHttp
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn retrofit2.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson & JSON
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepattributes Signature
-keepattributes *Annotation*


# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Play Core (In-App Updates, Reviews)
-keep class com.google.android.play.core.** { *; }

# Các lớp khác của ứng dụng cần giữ lại
-keep class com.com.vnu.students.** { *; }



# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Lifecycle
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# WebView
-keep class android.webkit.** { *; }
-dontwarn android.webkit.**

# Video Player
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Local Auth (Biometric)
-keep class androidx.biometric.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Image Picker & File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# inmapz (AAR library)
-keep class com.inmapz.** { *; }
-dontwarn com.inmapz.**

# Prevent stripping native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Prevent stripping Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Prevent stripping Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# R8 Full Mode - Keep class names
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Fix for Android 14/15 (SDK 35) - ClassLoader/DEX Loading
-keep class dalvik.system.** { *; }
-keep class dalvik.system.BaseDexClassLoader { *; }
-keep class dalvik.system.DexClassLoader { *; }
-keep class dalvik.system.PathClassLoader { *; }
-keep class dalvik.system.DexFile { *; }
-keep class dalvik.system.DexPathList { *; }
-keep class dalvik.system.DexPathList$Element { *; }
-dontwarn dalvik.system.**

# Multidex - Keep all classes
-keep class androidx.multidex.** { *; }
-keep class androidx.multidex.MultiDex { *; }
-keep class androidx.multidex.MultiDexApplication { *; }
-keep class android.support.multidex.** { *; }
-dontwarn androidx.multidex.**

# Keep all classes in the primary dex
-keep class com.vnu.students.** { *; }

# Google Play Core (SplitCompat)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Play Store Split Application
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Missing classes workaround for R8
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task