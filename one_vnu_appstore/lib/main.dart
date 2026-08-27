import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:students/bootstrap/app_bootstrap.dart';

import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/sync/views/vcore_sync_view.dart';
import 'package:vnu_core/modules/sync/vneid_deep_link_service.dart';
import 'package:vnu_core/modules/tabbar/views/vcore_tabbar_view.dart';
import 'package:vnu_core/services/app_update_coordinator.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_noi_tru/vnu_noi_tru.dart';

// Nếu cần bật DevicePreview thì mở lại import này.
// import 'package:device_preview/device_preview.dart';

/// Guide scope is installed globally in `VnuCore.runVnuApp()` around the
/// Navigator. Keep the main screen plain here; nested ShowCaseWidget instances
/// would split guide state between the root tabbar and pushed routes.
Widget _buildMainScreen() => const VcoreTabbarView();

Future<void> main() async {
  final bootstrap = await AppBootstrap.initialize();
  runApp(
    MyApp(
      message: bootstrap.initialMessage,
      firebaseReady: bootstrap.firebaseReady,
    ),
  );
}

class MyApp extends StatefulHookWidget {
  const MyApp({
    super.key,
    this.message,
    this.firebaseReady = true,
  });

  final RemoteMessage? message;
  final bool firebaseReady;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _appLinksSubscription;
  StreamSubscription<String>? _fcmTokenRefreshSubscription;

  bool _isOpeningVneidSyncView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRuntimeServices();
  }

  void _startRuntimeServices() {
    // Requirement Gate is independent from Firebase. It starts fetching during
    // Splash, but AppUpdateGate stays hidden until Splash has navigated away.
    unawaited(AppUpdateCoordinator.instance.start());

    unawaited(_initVneidDeepLinks());
    unawaited(_initializeNotificationRuntime());
  }

  Future<void> _initializeNotificationRuntime() async {
    await _initializationLocalPushNotificationPlugin();

    if (!widget.firebaseReady) {
      logWarning(
        '[RUNTIME] Firebase unavailable; skip FCM initialization only.',
      );
      return;
    }

    await _initFireBaseMessaging();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Covers Recent Apps, returning from Play Store/App Store and any normal
      // background -> foreground transition. If the installed version is still
      // below minimumVersion, the global gate remains blocking.
      unawaited(AppUpdateCoordinator.instance.onAppResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppUpdateCoordinator.instance.stop();
    _appLinksSubscription?.cancel();
    _fcmTokenRefreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    VnuCore().loginSucces = (token) async {
      logInfo('Login success');

      // Guide scope already wraps the root Navigator in VnuCore.runVnuApp().
      VnuCore().gotoMainScreen(_buildMainScreen());

      _openPendingVneidCallback();

      if (widget.message != null) {
        _handleNotificationTapped(context, widget.message?.data);
      }
    };

    return VnuCore().runVnuApp(mainScreen: _buildMainScreen());
  }

  Future<void> _initVneidDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();

      if (initialLink != null) {
        _handleVneidDeepLink(initialLink);
      }
    } catch (e) {
      logError('VNeID getInitialLink error: $e');
    }

    _appLinksSubscription = _appLinks.uriLinkStream.listen(
      _handleVneidDeepLink,
      onError: (Object error) {
        logError('VNeID uriLinkStream error: $error');
      },
    );
  }

  void _handleVneidDeepLink(Uri uri) {
    logInfo('==== VNeID DEEP LINK RECEIVED IN MAIN ====');
    logInfo('VNeID raw uri: $uri');
    logInfo('VNeID scheme: ${uri.scheme}');
    logInfo('VNeID host: ${uri.host}');
    logInfo('VNeID path: ${uri.path}');
    logInfo('VNeID pathSegments: ${uri.pathSegments}');
    logInfo('VNeID queryParameters: ${uri.queryParameters}');

    final handled = VneidDeepLinkService().handleUri(uri);

    logInfo('VNeID handled by service: $handled');

    if (handled) {
      _openPendingVneidCallback();
    }
  }

  void _openPendingVneidCallback() {
    if (!mounted ||
        Globals().token.isEmpty ||
        _isOpeningVneidSyncView ||
        !VneidDeepLinkService().hasPendingCallback ||
        VneidDeepLinkService().isSyncViewVisible) {
      return;
    }

    _isOpeningVneidSyncView = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;

      if (!mounted ||
          context == null ||
          !VneidDeepLinkService().hasPendingCallback ||
          VneidDeepLinkService().isSyncViewVisible) {
        _isOpeningVneidSyncView = false;
        return;
      }

      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const VcoreSyncView()))
          .whenComplete(() {
        _isOpeningVneidSyncView = false;
      });
    });
  }

  Future<void> _initializationLocalPushNotificationPlugin() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == null) return;

        try {
          final Map<String, dynamic> payload = jsonDecode(details.payload!);

          _handleNotificationTapped(context, payload);
        } catch (e) {
          logError(e.toString());
        }
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'OneVNU',
        'OneVNU',
        description: 'OneVNU Notification',
        importance: Importance.high,
        playSound: true,
      );

      unawaited(
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel),
      );
    }
  }

  Future<void> _initFireBaseMessaging() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (Platform.isIOS) {
        // iOS does not show foreground notification banners unless these
        // presentation options are enabled. AppBootstrap also sets them early;
        // repeating here after permission keeps runtime initialization robust.
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      await _fcmTokenRefreshSubscription?.cancel();
      _fcmTokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        final normalized = token.trim();
        if (normalized.isEmpty) return;

        try {
          // Works for both normal USER and APPLICANT sessions. The backend
          // resolves the current access token from the Authorization header.
          await VnuCore().addFirebaseToken(normalized);
          logInfo('[FCM] refreshed device token synchronized');
        } catch (error) {
          logError('[FCM] token refresh sync failed: $error');
        }
      });

      FirebaseMessaging.onMessage.listen((event) {
        _showLocalPushNotification(event);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((event) {
        _handleNotificationTapped(context, event.data);
      });
    } catch (e) {
      logError('[FCM] runtime initialization failed: $e');
    }
  }

  void _handleNotificationTapped(
      BuildContext context,
      Map<String, dynamic>? message,
      ) {
    VnuCore().handleNotificationTapped(context, message);

    VNUNoiTru().handleNotificationTapped(message);
  }

  Future<void> _showLocalPushNotification(RemoteMessage message) async {
    // On iOS, a normal FCM notification payload is already rendered as a
    // foreground system banner because presentation options are enabled. Do not
    // create a second local notification for the same message.
    if (Platform.isIOS && message.notification != null) {
      return;
    }

    final title = (message.notification?.title ??
            message.data['title'] ??
            message.data['notificationTitle'] ??
            '')
        .toString()
        .trim();
    final body = (message.notification?.body ??
            message.data['body'] ??
            message.data['message'] ??
            message.data['content'] ??
            '')
        .toString()
        .trim();

    // Data-only messages do not automatically create a banner on iOS. In that
    // case, use flutter_local_notifications as the foreground fallback.
    if (title.isEmpty && body.isEmpty) {
      logWarning('[FCM] foreground message has no visible title/body');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'OneVNU',
      'OneVNU',
      channelDescription: 'OneVNU Notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: Random().nextInt(10000),
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );

    logSuccess('[FCM] foreground local notification shown');
  }

  void onDidReceiveLocalNotification(
      int id,
      String title,
      String? body,
      String? payload,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(body ?? ''),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }
}



