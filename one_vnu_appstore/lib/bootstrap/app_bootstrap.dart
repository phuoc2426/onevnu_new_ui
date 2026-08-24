import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:students/firebase_options.dart';
import 'package:vnu_core/common/guide/global/app_guide_global_initializer.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/services/services_url.dart';

class AppBootstrapResult {
  const AppBootstrapResult({
    required this.firebaseReady,
    this.initialMessage,
  });

  final bool firebaseReady;
  final RemoteMessage? initialMessage;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    logError('[BOOTSTRAP] Firebase background init failed: $e');
  }

  logInfo('[FCM] background message id=${message.messageId ?? '-'}');
}

class AppBootstrap {
  AppBootstrap._();

  static Future<AppBootstrapResult> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    final firebaseReady = await _initializeFirebase();
    _installAsyncErrorHandler(firebaseReady: firebaseReady);

    RemoteMessage? initialMessage;
    if (firebaseReady) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      } catch (e, stack) {
        logError('[BOOTSTRAP] Firebase Messaging init failed: $e');
        await _recordNonFatalIfPossible(e, stack, firebaseReady: firebaseReady);
      }
    }

    try {
      await ServicesUrl().init();
    } catch (e, stack) {
      // Core ONEVNU base URL đã có default cố định. Không chặn toàn bộ startup
      // chỉ vì SharedPreferences/config phụ không khởi tạo được.
      logError('[BOOTSTRAP] ServicesUrl init failed: $e');
      await _recordNonFatalIfPossible(e, stack, firebaseReady: firebaseReady);
    }

    AppGuideGlobalInitializer.ensureInitialized();

    logInfo(
      '[BOOTSTRAP] completed firebaseReady=$firebaseReady '
      'hasInitialMessage=${initialMessage != null}',
    );

    return AppBootstrapResult(
      firebaseReady: firebaseReady,
      initialMessage: initialMessage,
    );
  }

  static Future<bool> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (e) {
      logError('[BOOTSTRAP] Firebase init failed: $e');
      return false;
    }
  }

  static void _installAsyncErrorHandler({required bool firebaseReady}) {
    PlatformDispatcher.instance.onError = (error, stack) {
      if (firebaseReady) {
        try {
          FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            fatal: true,
          );
        } catch (_) {
          // Không để chính crash reporter tạo thêm exception.
        }
      }
      logError('[ASYNC_ERROR] $error');
      return true;
    };
  }

  static Future<void> _recordNonFatalIfPossible(
    Object error,
    StackTrace stack, {
    required bool firebaseReady,
  }) async {
    if (!firebaseReady) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: false,
      );
    } catch (_) {
      // Best effort only.
    }
  }
}
