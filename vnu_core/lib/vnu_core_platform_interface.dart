import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'vnu_core_method_channel.dart';

abstract class VnuCorePlatform extends PlatformInterface {
  /// Constructs a VnuCorePlatform.
  VnuCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static VnuCorePlatform _instance = MethodChannelVnuCore();

  /// The default instance of [VnuCorePlatform] to use.
  ///
  /// Defaults to [MethodChannelVnuCore].
  static VnuCorePlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VnuCorePlatform] when
  /// they register themselves.
  static set instance(VnuCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
