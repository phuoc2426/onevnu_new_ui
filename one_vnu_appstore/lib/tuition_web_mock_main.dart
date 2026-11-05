import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/modules/tuition/views/vcore_tuition_view.dart';

/// Launch the ACTUAL VcoreTuitionView without ONEVNU login or a live backend.
/// Use `flutter run -d chrome -t lib/tuition_web_mock_main.dart`.
/// No request can be made to the ULIS payment system in mock mode.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  assert(() {
    debugPrint('[ONEVNU_TUITION] FULL_FLUTTER_UI_MOCK | NO_NETWORK');
    return true;
  }());
  // A release build from this mock entrypoint must NEVER fall back to the
  // production network path just because kDebugMode becomes false.
  if (!kDebugMode) {
    runApp(const MaterialApp(home: Scaffold(
      body: Center(child: Text('Mock học phí chỉ chạy ở Flutter Debug.')),
    )));
    return;
  }
  runApp(MaterialApp(
    title: 'ONEVNU — Tuition Mock',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const VcoreTuitionView(
      universityId: 4,
      mockGateway: true,
    ),
  ));
}
