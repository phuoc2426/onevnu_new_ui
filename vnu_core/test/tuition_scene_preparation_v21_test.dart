import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_scene_preparation.dart';

void main() {
  test('V21 scene loading has explicit maximum time budgets', () {
    expect(TuitionScenePreparationConfig.entryMaxWait,
        const Duration(milliseconds: 1300));
    expect(TuitionScenePreparationConfig.printerMaxWait,
        const Duration(milliseconds: 550));
    expect(TuitionScenePreparationConfig.printerMaxWait <
        TuitionScenePreparationConfig.entryMaxWait, isTrue);
  });

  test('warm cache immediately opens without artificial minimum delay', () async {
    expect(await TuitionWarmupDeadline.wait(Future<void>.value(),
      const Duration(milliseconds: 500)), isTrue);
  });

  test('unfinished decoder cannot hold UI beyond its deadline', () async {
    final pending = Completer<void>();
    final ready = await TuitionWarmupDeadline.wait(pending.future,
      const Duration(milliseconds: 10));
    expect(ready, isFalse);
    // The underlying decode is allowed to finish in the background.
    pending.complete();
  });

  test('failed asset preloading uses fallback without raising', () async {
    final failed = Future<void>.error(StateError('asset missing'));
    expect(await TuitionWarmupDeadline.wait(failed,
      const Duration(milliseconds: 500)), isFalse);
  });

  testWidgets('entry loading is centered and blocks interactions', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Stack(children: [
      Positioned.fill(child: TextButton(
        onPressed: () => tapped = true, child: const Text('Pay now'))),
      const TuitionScenePreparationOverlay(entering: true),
    ]))));
    expect(find.text('Đang chuẩn bị giao diện…'), findsOneWidget);
    await tester.tap(find.text('Pay now'), warnIfMissed: false);
    expect(tapped, isFalse);
  });

  testWidgets('QR preflight shows a different loading label', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Stack(
      children: [TuitionScenePreparationOverlay()],
    ))));
    expect(find.text('Đang chuẩn bị hiệu ứng…'), findsOneWidget);
  });
}
