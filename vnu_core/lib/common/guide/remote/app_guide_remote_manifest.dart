import '../flow/app_guide_flow.dart';
import '../flow/app_guide_flow_step.dart';

class AppGuideRemoteManifest {
  const AppGuideRemoteManifest({
    required this.schemaVersion,
    required this.manifestRevision,
    required this.flows,
    this.generatedAt,
  });

  final int schemaVersion;
  final String manifestRevision;
  final DateTime? generatedAt;
  final List<AppGuideFlow> flows;

  factory AppGuideRemoteManifest.fromJson(Map<String, dynamic> json) {
    final rawFlows = json['flows'];
    final flows = rawFlows is List
        ? rawFlows
            .whereType<Map>()
            .map(
              (entry) => _flowFromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .whereType<AppGuideFlow>()
            .toList()
        : <AppGuideFlow>[];

    flows.sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      return priority != 0 ? priority : a.id.compareTo(b.id);
    });

    return AppGuideRemoteManifest(
      schemaVersion: _asInt(json['schemaVersion'], fallback: 1),
      manifestRevision: (json['manifestRevision'] ?? '').toString(),
      generatedAt: DateTime.tryParse((json['generatedAt'] ?? '').toString()),
      flows: flows,
    );
  }

  AppGuideFlow? firstFlowForTrigger(String triggerCode) {
    for (final flow in flows) {
      if (flow.triggerCode == triggerCode) return flow;
    }
    return null;
  }

  List<AppGuideFlow> flowsForTrigger(String triggerCode) {
    return flows.where((flow) => flow.triggerCode == triggerCode).toList();
  }

  static AppGuideFlow? _flowFromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString().trim();
    final title = (json['title'] ?? '').toString().trim();
    if (code.isEmpty || title.isEmpty) return null;

    final rawSteps = json['steps'];
    final steps = rawSteps is List
        ? rawSteps
            .whereType<Map>()
            .map((entry) => _stepFromJson(Map<String, dynamic>.from(entry)))
            .whereType<AppGuideFlowStep>()
            .toList()
        : <AppGuideFlowStep>[];

    return AppGuideFlow(
      id: code,
      title: title,
      description: _nullableText(json['description']),
      triggerCode: (json['triggerCode'] ?? AppGuideFlow.manualTrigger)
          .toString()
          .trim(),
      revision: _asInt(json['revision']),
      runOnce: _asBool(json['runOnce'], fallback: true),
      priority: _asInt(json['priority']),
      steps: steps,
    );
  }

  static AppGuideFlowStep? _stepFromJson(Map<String, dynamic> json) {
    final targetId = (json['targetId'] ?? '').toString().trim();
    if (targetId.isEmpty) return null;

    final orderIndex = _asInt(json['orderIndex']);
    final guid = (json['guid'] ?? '').toString().trim();

    return AppGuideFlowStep(
      id: guid.isNotEmpty ? guid : '$targetId#$orderIndex',
      itemId: targetId,
      title: _nullableText(json['title']),
      description: _nullableText(json['description']),
      beforeActionId: _nullableText(json['beforeActionId']),
      fallbackTargetId: _nullableText(json['fallbackTargetId']),
      delayMs: _asInt(json['delayMs'], fallback: 220).clamp(0, 5000).toInt(),
      skipIfUnavailable: _asBool(
        json['skipIfUnavailable'],
        fallback: true,
      ),
    );
  }

  static String? _nullableText(dynamic value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }
}
