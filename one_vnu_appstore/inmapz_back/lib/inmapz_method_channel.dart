import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'inmapz_platform_interface.dart';

/// An implementation of [InmapzPlatform] that uses method channels.
class MethodChannelInmapz extends InmapzPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('inmapz');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
