import 'package:flutter_test/flutter_test.dart';
import 'package:inmapz/inmapz.dart';
import 'package:inmapz/inmapz_platform_interface.dart';
import 'package:inmapz/inmapz_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInmapzPlatform
    with MockPlatformInterfaceMixin
    implements InmapzPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final InmapzPlatform initialPlatform = InmapzPlatform.instance;

  test('$MethodChannelInmapz is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInmapz>());
  });

  test('getPlatformVersion', () async {
    Inmapz inmapzPlugin = Inmapz();
    MockInmapzPlatform fakePlatform = MockInmapzPlatform();
    InmapzPlatform.instance = fakePlatform;

    expect(await inmapzPlugin.getPlatformVersion(), '42');
  });
}
