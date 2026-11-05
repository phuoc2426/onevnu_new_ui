import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration test run FROM one_vnu_appstore, NOT the vnu_core package.
/// It verifies what the host application actually bundles for vnu_core.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prefix = 'packages/vnu_core/assets/tinktalk/';
  const names = ['list1.png', 'detail1.png', 'background_qr.png'];

  test('Host app manifest contains new ticket and QR images', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest.listAssets().toSet();
    for (final name in names) {
      expect(keys, contains('$prefix$name'), reason:
          'Missing package asset $prefix$name. Fix vnu_core/pubspec.yaml.');
    }
  });

  for (final name in names) {
    test('APK/source bundle can decode $name', () async {
      final byteData = await rootBundle.load('$prefix$name');
      expect(byteData.lengthInBytes, greaterThan(0));
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List(
          byteData.offsetInBytes, byteData.lengthInBytes));
      try {
        final image = (await codec.getNextFrame()).image;
        try {
          expect(image.width, greaterThan(20));
          expect(image.height, greaterThan(20));
          final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          expect(rgba, isNotNull);
          if (name != 'background_qr.png') {
            final a = rgba!;
            int alpha(int x, int y) => a.getUint8(
                (y * image.width + x) * 4 + 3);
            final corners = <int>[
              alpha(0, 0), alpha(image.width - 1, 0),
              alpha(0, image.height - 1),
              alpha(image.width - 1, image.height - 1),
            ];
            // The requested ticket has cut-outs/notches around its outline.
            // If all corners are opaque, the PNG cannot clip them as intended.
            expect(corners.any((value) => value < 255), isTrue,
                reason: '$name has opaque corners $corners. '
                'Export an RGBA PNG with transparent space outside the mask.');
          }
        } finally {
          image.dispose();
        }
      } finally {
        codec.dispose();
      }
    });
  }
}
