import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_row.dart';

Widget _host({required double width, required TextScaler scaler}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 700), textScaler: scaler),
      child: Scaffold(
        body: SizedBox(
          width: width,
          child: VnuResponsiveRow(
            minChildWidth: 180,
            children: const [
              SizedBox(key: Key('a'), height: 52),
              SizedBox(key: Key('b'), height: 52),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('keeps row when effective width is sufficient', (tester) async {
    await tester.pumpWidget(_host(width: 800, scaler: TextScaler.noScaling));
    final a = tester.getTopLeft(find.byKey(const Key('a')));
    final b = tester.getTopLeft(find.byKey(const Key('b')));
    expect(a.dy, b.dy);
    expect(b.dx, greaterThan(a.dx));
  });

  testWidgets('stacks at narrow width', (tester) async {
    await tester.pumpWidget(_host(width: 320, scaler: TextScaler.noScaling));
    final a = tester.getTopLeft(find.byKey(const Key('a')));
    final b = tester.getTopLeft(find.byKey(const Key('b')));
    expect(a.dx, b.dx);
    expect(b.dy, greaterThan(a.dy));
  });

  testWidgets('large text can force stacking before physical width is tiny', (tester) async {
    await tester.pumpWidget(_host(width: 600, scaler: const TextScaler.linear(2)));
    final a = tester.getTopLeft(find.byKey(const Key('a')));
    final b = tester.getTopLeft(find.byKey(const Key('b')));
    expect(a.dx, b.dx);
    expect(b.dy, greaterThan(a.dy));
  });
}
