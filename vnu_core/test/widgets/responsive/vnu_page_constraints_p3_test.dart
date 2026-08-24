import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/responsive/vnu_page_constraints.dart';

void main() {
  testWidgets('form content is capped on wide screens', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: VnuPageConstraints(
              width: VnuPageWidth.form,
              child: SizedBox(key: Key('content'), height: 20),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('content'))).width, 720);
  });
}
