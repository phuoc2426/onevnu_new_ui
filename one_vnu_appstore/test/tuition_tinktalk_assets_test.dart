import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const assetRoot = 'packages/vnu_core/assets/tinktalk/';
  for (final name in <String>['list1.png', 'detail1.png', 'background_qr.png']) {
    test('vnu_core ticket asset bundled: $name', () async {
      final bytes = await rootBundle.load('$assetRoot$name');
      expect(bytes.lengthInBytes, greaterThan(50));
    });
  }
}
