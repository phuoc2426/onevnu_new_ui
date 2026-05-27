import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'vnu_core_platform_interface.dart';

/// An implementation of [VnuCorePlatform] that uses method channels.
class MethodChannelVnuCore extends VnuCorePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('vnu_core');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
