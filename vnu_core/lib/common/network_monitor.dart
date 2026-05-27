import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/utils.dart';

class NetworkMonitor {
  NetworkMonitor._internal() {}

  static final NetworkMonitor _singleton = NetworkMonitor._internal();

  factory NetworkMonitor() {
    return _singleton;
  }

  StreamSubscription<List<ConnectivityResult>>? subscription;
  ConnectivityResult? lastConnectivity;
  bool isFirstListen = true;

  startListen() {
    if (subscription != null) {
      debugPrint("CANCEL startListen --> Connectivity running.....");
      return;
    }
    subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> connectivityResult) {
        var isConnected = true;

        // Received changes in available connectivity types!
        // This condition is for demo purposes only to explain every connection type.
        // Use conditions which work for your requirements.
        if (connectivityResult.contains(ConnectivityResult.mobile)) {
          // Mobile network available.
          lastConnectivity = ConnectivityResult.mobile;
          print('Mobile network available.');
        } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
          // Wi-fi is available.
          // Note for Android:
          // When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
          lastConnectivity = ConnectivityResult.wifi;
          print('Wi-fi is available.');
        } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
          // Ethernet connection available.
          lastConnectivity = ConnectivityResult.ethernet;
        } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
          // Vpn connection active.
          // Note for iOS and macOS:
          // There is no separate network interface type for [vpn].
          // It returns [other] on any device (also simulator)
          lastConnectivity = ConnectivityResult.vpn;
          print('Vpn connection active.');
        } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
          // Bluetooth connection available.
          lastConnectivity = ConnectivityResult.bluetooth;
          print('Bluetooth connection available.');
        } else if (connectivityResult.contains(ConnectivityResult.other)) {
          // Connected to a network which is not in the above mentioned networks.
          lastConnectivity = ConnectivityResult.other;
          print(
              'Connected to a network which is not in the above mentioned networks.');
        } else if (connectivityResult.contains(ConnectivityResult.none)) {
          // No available network types
          isConnected = false;
          lastConnectivity = ConnectivityResult.none;
          print('No available network types --- NO Network');
          snackBarWarning(
              'Không có kết nối Internet. Vui lòng kiểm tra lại kết nối Internet.');
        }

        if (isConnected == true && isFirstListen == false) {
          snackBarSuccess('Đã khôi phục kết nối internet.');
        }

        isFirstListen = false;
      },
    );
  }
}
