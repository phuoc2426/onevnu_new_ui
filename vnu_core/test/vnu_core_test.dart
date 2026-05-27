import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_core/vnu_core_platform_interface.dart';
import 'package:vnu_core/vnu_core_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVnuCorePlatform
    with MockPlatformInterfaceMixin
    implements VnuCorePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VnuCorePlatform initialPlatform = VnuCorePlatform.instance;

  test('$MethodChannelVnuCore is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVnuCore>());
  });

  test('getPlatformVersion', () async {
    VnuCore vnuCorePlugin = VnuCore();
  });
}
