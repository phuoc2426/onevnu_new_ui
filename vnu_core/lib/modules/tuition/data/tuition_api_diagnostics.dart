import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Debug-only payment traces. Never record JWT, X_API_KEY, student code,
/// canonicalStudentId, paymentRequestId, payload or upstream response body.
class TuitionApiEvent {
  const TuitionApiEvent({required this.time, required this.step,
    required this.phase, this.statusCode, this.elapsedMs, this.note});

  final DateTime time;
  final String step;
  final String phase;
  final int? statusCode;
  final int? elapsedMs;
  final String? note;

  String get line {
    final timeLabel = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    return '[$timeLabel] $step | $phase'
        '${statusCode == null ? '' : ' | HTTP $statusCode'}'
        '${elapsedMs == null ? '' : ' | ${elapsedMs}ms'}'
        '${note == null ? '' : ' | $note'}';
  }
}

class TuitionApiDiagnostics extends ChangeNotifier {
  TuitionApiDiagnostics._();
  static final TuitionApiDiagnostics instance = TuitionApiDiagnostics._();
  final List<TuitionApiEvent> _events = <TuitionApiEvent>[];

  List<TuitionApiEvent> get events => List<TuitionApiEvent>.unmodifiable(_events);

  void record(String step, String phase, {int? statusCode,
      int? elapsedMs, String? note}) {
    if (!kDebugMode) return;
    // Callers supply only short, constant enum-like labels, never error text.
    final event = TuitionApiEvent(time: DateTime.now(), step: step,
      phase: phase, statusCode: statusCode, elapsedMs: elapsedMs, note: note);
    _events.add(event);
    if (_events.length > 90) _events.removeAt(0);
    debugPrint('[ONEVNU_TUITION] ${event.line}');
    notifyListeners();
  }

  String get exportText => _events.map((event) => event.line).join('\n');
  void clear() {
    _events.clear();
    notifyListeners();
  }
}

/// In-app diagnostics available in kDebugMode, including after a failed login.
/// The clipboard export contains only sanitized stage/status/duration metadata.
class TuitionDebugPanel {
  const TuitionDebugPanel._();

  static Future<void> open(BuildContext context) async {
    if (!kDebugMode) return;
    final diagnostics = TuitionApiDiagnostics.instance;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius:
        BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) => SafeArea(top: false,
        child: SizedBox(height: MediaQuery.sizeOf(sheetContext).height * 0.70,
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 18, 10, 8),
              child: Row(children: [
                const Expanded(child: Text('ULIS API - Debug trace',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                IconButton(tooltip: 'Copy safe logs',
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: diagnostics.exportText)),
                  icon: const Icon(Icons.copy_outlined, color: Colors.black)),
                IconButton(tooltip: 'Clear logs',
                  onPressed: diagnostics.clear,
                  icon: const Icon(Icons.delete_outline, color: Colors.black)),
              ])),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('No tokens, student IDs or QR values are logged.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)))),
            const Divider(height: 20),
            Expanded(child: AnimatedBuilder(animation: diagnostics,
              builder: (context, _) {
                final events = diagnostics.events.reversed.toList();
                if (events.isEmpty) {
                  return const Center(child: Text('No API requests recorded yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, index) {
                    final event = events[index];
                    final failed = event.phase == 'FAILED' ||
                        (event.statusCode != null && event.statusCode! >= 400);
                    return Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(failed ? Icons.error_outline : Icons.check_circle_outline,
                          size: 18, color: failed ? Colors.red[600] : Colors.green[700]),
                        const SizedBox(width: 9),
                        Expanded(child: SelectableText(event.line,
                          style: const TextStyle(fontFamily: 'monospace',
                            fontSize: 12, height: 1.4))),
                      ]);
                  },
                );
              })),
          ])),
      ));
  }
}
