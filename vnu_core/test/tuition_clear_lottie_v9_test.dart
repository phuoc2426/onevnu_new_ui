import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:vnu_core/modules/tuition/data/tuition_session_recovery_policy.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_clear_session_overlay.dart';

void main() {
  testWidgets('toolbar renders the clear.json Lottie rather than a Material icon',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: TuitionClearLottieIcon())),
    ));
    expect(find.byKey(const ValueKey<String>('tuition_clear_appbar_lottie')),
        findsOneWidget);
    expect(find.byType(Lottie), findsOneWidget);
    expect(TuitionClearArtwork.asset,
        'assets/icons/animation_icons/clear.json');
  });

  test('third recoverable read triggers automatic session renewal once', () {
    final policy = TuitionSessionRecoveryPolicy();
    expect(policy.recordRecoverableMiss(), isFalse);
    expect(policy.recordRecoverableMiss(), isFalse);
    expect(policy.recordRecoverableMiss(), isTrue);
    expect(policy.recordRecoverableMiss(), isFalse);
  });

  test('V9 automatic renewal is connected to the very same overlay as tap', () {
    final source = File('lib/modules/tuition/views/vcore_tuition_view.dart')
        .readAsStringSync();
    expect(source, contains("_showClearAnimation(reason: 'manual_lottie_button')"));
    expect(source, contains("_showClearAnimation(reason: 'three_consecutive_payable_misses')"));
    expect(source, contains('readyToDismiss: !_manualRefreshing &&'));
    expect(source, contains('!_autoSessionRefreshing && !_connecting'));
  });
}
