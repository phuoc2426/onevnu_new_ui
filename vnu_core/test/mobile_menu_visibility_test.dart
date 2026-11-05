import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/mobile_menu/mobile_menu_preview_policy.dart';

void main() {
  test('tuition is restricted to ULIS universityId 4 by the local policy', () {
    expect(MobileMenuPreviewPolicy.isVisible('native:Học phí', universityId: 4), isTrue);
    expect(MobileMenuPreviewPolicy.isVisible('native:Học phí', universityId: 1), isFalse);
    expect(MobileMenuPreviewPolicy.isVisible('native:Học phí', universityId: null), isFalse);
  });
  test('one door remains available without university filtering', () {
    expect(MobileMenuPreviewPolicy.isVisible('native:Thủ tục', universityId: null), isTrue);
  });
}
