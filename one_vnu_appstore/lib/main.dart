import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:students/firebase_options.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/sync/views/vcore_sync_view.dart';
import 'package:vnu_core/modules/sync/vneid_deep_link_service.dart';
import 'package:vnu_core/modules/tabbar/views/vcore_tabbar_view.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_noi_tru/vnu_noi_tru.dart';
import 'package:device_preview/device_preview.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    logError(e.toString());
  }

  logInfo('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    logError(e.toString());
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  HttpOverrides.global = MyHttpOverrides();

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  await ServicesUrl().init();

  final RemoteMessage? message =
  await FirebaseMessaging.instance.getInitialMessage();

  // Để sử dụng device_preview, hãy mở comment import ở đầu file và đoạn code dưới đây,
  // đồng thời comment lại dòng `runApp(MyApp(message: message));` phía dưới.
  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     builder: (context) => MyApp(message: message),
  //   ),
  // );
  runApp(MyApp(message: message));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulHookWidget {
  const MyApp({
    super.key,
    this.message,
  });

  final RemoteMessage? message;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _appLinksSubscription;
  bool _isOpeningVneidSyncView = false;

  @override
  void initState() {
    super.initState();

    _initFireBaseMessaging();
    _initializationLocalPushNotificationPlugin();
    _initRemoteConfig();
    _initVneidDeepLinks();
  }

  @override
  void dispose() {
    _appLinksSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    VnuCore().loginSucces = (token) async {
      logInfo('Login success');

      VnuCore().gotoMainScreen(
        const VcoreTabbarView(),
      );

      _openPendingVneidCallback();

      if (widget.message != null) {
        _handleNotificationTapped(
          context,
          widget.message?.data,
        );
      }
    };

    return VnuCore().runVnuApp(
      mainScreen: const VcoreTabbarView(),
    );
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

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VcoreSyncView()),
      ).whenComplete(() {
        _isOpeningVneidSyncView = false;
      });
    });
  }

  Future<void> _initRemoteConfig() async {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: const Duration(seconds: 1),
      ),
    );

    await remoteConfig.fetchAndActivate();

    logInfo('_initRemoteConfig');

    final Map<String, RemoteConfigValue> configValue = remoteConfig.getAll();
    logError(configValue.keys.toString());

    VnuCore().checkUpdateNewVersion(
      foreVersion: remoteConfig.getString('fore'),
      iosVersion: remoteConfig.getString('ios'),
      iosUrl: remoteConfig.getString('iOSUrl'),
      androidVersion: remoteConfig.getString('android'),
      androidUrl: remoteConfig.getString('androidUrl'),
    );
  }

  void _initializationLocalPushNotificationPlugin() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == null) return;

        try {
          final Map<String, dynamic> payload = jsonDecode(details.payload!);

          _handleNotificationTapped(
            context,
            payload,
          );
        } catch (e) {
          logError(e.toString());
        }
      },
    );
  }

  Future<void> _initFireBaseMessaging() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((event) {
      _showLocalPushNotification(event);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      _handleNotificationTapped(
        context,
        event.data,
      );
    });
  }

  void _handleNotificationTapped(
      BuildContext context,
      Map<String, dynamic>? message,
      ) {
    VnuCore().handleNotificationTapped(
      context,
      message,
    );

    VNUNoiTru().handleNotificationTapped(message);
  }

  Future<void> _showLocalPushNotification(RemoteMessage message) async {
    if (Platform.isIOS) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'OneVNU',
      'OneVNU',
      channelDescription: 'OneVNU Notification',
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
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );

    logSuccess('flutterLocalNotificationsPlugin show push');
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
