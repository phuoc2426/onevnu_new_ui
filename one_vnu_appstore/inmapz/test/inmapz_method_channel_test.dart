import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inmapz/inmapz_method_channel.dart';

void main() {
  MethodChannelInmapz platform = MethodChannelInmapz();
  const MethodChannel channel = MethodChannel('inmapz');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
