import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:students/firebase_options.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:vnu_core/common/error/app_error_reporter.dart';
import 'package:vnu_core/common/guide/global/app_guide_global_initializer.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/error_widget.dart';

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
    _configureErrorReporter(firebaseReady: firebaseReady);
    _installGlobalErrorHandlers();

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
        final appError = AppErrorMapper.map(e, stackTrace: stack);
        await AppErrorReporter.report(appError, stackTrace: stack);
      }
    }

    try {
      await ServicesUrl().init();
    } catch (e, stack) {
      logError('[BOOTSTRAP] ServicesUrl init failed: $e');
      final appError = AppErrorMapper.map(e, stackTrace: stack);
      await AppErrorReporter.report(appError, stackTrace: stack);
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

  static void _configureErrorReporter({required bool firebaseReady}) {
    if (!firebaseReady) {
      AppErrorReporter.configure(null);
      return;
    }

    AppErrorReporter.configure(
      (
        Object error,
        StackTrace stackTrace, {
        required bool fatal,
        Map<String, Object?>? context,
      }) async {
        try {
          if (context != null) {
            for (final entry in context.entries) {
              final value = entry.value;
              if (value == null) continue;
              await FirebaseCrashlytics.instance.setCustomKey(
                'app_error_${entry.key}',
                value.toString(),
              );
            }
          }

          await FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            fatal: fatal,
          );
        } catch (_) {
          // Crash reporting is best effort and must never create a new crash.
        }
      },
    );
  }

  static void _installGlobalErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      final stack = details.stack ?? StackTrace.current;
      final appError = AppErrorMapper.map(
        details.exception,
        stackTrace: stack,
      );

      unawaited(
        AppErrorReporter.report(
          appError,
          stackTrace: stack,
          fatal: true,
          context: <String, Object?>{
            'library': details.library,
          },
        ),
      );
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const VnuUnexpectedErrorWidget();
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final appError = AppErrorMapper.map(
        error,
        stackTrace: stack,
      );
      unawaited(
        AppErrorReporter.report(
          appError,
          stackTrace: stack,
          fatal: true,
          context: const <String, Object?>{
            'source': 'PlatformDispatcher',
          },
        ),
      );
      return true;
    };
  }
}
