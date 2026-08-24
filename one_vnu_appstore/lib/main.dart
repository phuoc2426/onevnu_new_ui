import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:students/bootstrap/app_bootstrap.dart';

import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/guide/guide.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/sync/views/vcore_sync_view.dart';
import 'package:vnu_core/modules/sync/vneid_deep_link_service.dart';
import 'package:vnu_core/modules/tabbar/views/vcore_tabbar_view.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_noi_tru/vnu_noi_tru.dart';

// Nếu cần bật DevicePreview thì mở lại import này.
// import 'package:device_preview/device_preview.dart';

/// Bọc một screen bằng guide scope.
///
/// Lý do cần helper này:
/// - VnuCore().runVnuApp(mainScreen: ...)
/// - VnuCore().gotoMainScreen(...)
///
/// đều có thể tạo lại main screen sau login / logout / navigation.
/// Nếu truyền thẳng `const VcoreTabbarView()` thì màn Home sau đó có thể không còn
/// nằm dưới AppGuideRegistryScope, gây lỗi:
///
/// AppGuideRegistryScope not found.
Widget _buildGuideHost({required Widget child}) {
  return AppGuideRegistryScope(
    registry: globalAppGuideRegistry,
    child: AppShowcaseScope(child: child),
  );
}

Widget _buildMainScreen() {
  return _buildGuideHost(child: const VcoreTabbarView());
}

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

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _appLinksSubscription;

  bool _isOpeningVneidSyncView = false;

  @override
  void initState() {
    super.initState();
    _startRuntimeServices();
  }

  void _startRuntimeServices() {
    _initializationLocalPushNotificationPlugin();
    unawaited(_initVneidDeepLinks());

    if (!widget.firebaseReady) {
      logWarning(
        '[RUNTIME] Firebase unavailable; skip FCM and Remote Config initialization.',
      );
      return;
    }

    unawaited(_initFireBaseMessaging());
    unawaited(_initRemoteConfig());
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

      /// Quan trọng:
      /// Không truyền thẳng `const VcoreTabbarView()` nữa.
      /// Phải truyền screen đã được bọc AppGuideRegistryScope + AppShowcaseScope.
      VnuCore().gotoMainScreen(_buildMainScreen());

      _openPendingVneidCallback();

      if (widget.message != null) {
        _handleNotificationTapped(context, widget.message?.data);
      }
    };

    /// Quan trọng:
    /// mainScreen cũng phải dùng `_buildMainScreen()`.
    /// Không dùng `const VcoreTabbarView()` trực tiếp.
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

  Future<void> _initRemoteConfig() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(seconds: 1),
        ),
      );

      await remoteConfig.fetchAndActivate();

      final configValue = remoteConfig.getAll();
      logInfo('[REMOTE_CONFIG] keys=${configValue.keys.join(',')}');

      await VnuCore().checkUpdateNewVersion(
        foreVersion: remoteConfig.getString('fore'),
        iosVersion: remoteConfig.getString('ios'),
        iosUrl: remoteConfig.getString('iOSUrl'),
        androidVersion: remoteConfig.getString('android'),
        androidUrl: remoteConfig.getString('androidUrl'),
      );
    } catch (e) {
      // Remote Config là cấu hình từ xa; lỗi fetch/activate không được làm app
      // văng khỏi startup. Requirement Gate sẽ xử lý policy bắt buộc ở phase sau.
      logError('[REMOTE_CONFIG] initialization failed: $e');
    }
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

          _handleNotificationTapped(context, payload);
        } catch (e) {
          logError(e.toString());
        }
      },
    );
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
