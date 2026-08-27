import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/version_utils.dart';

import 'app_update_policy.dart';

enum AppUpdateRequirement {
  allowed,
  optional,
  force,
}

class AppUpdateEvaluation {
  const AppUpdateEvaluation({
    required this.requirement,
    required this.platformPolicy,
    required this.currentVersion,
    this.minimumVersion,
    this.latestVersion,
  });

  final AppUpdateRequirement requirement;
  final AppUpdatePlatformPolicy platformPolicy;
  final Version currentVersion;
  final Version? minimumVersion;
  final Version? latestVersion;

  bool get isForce => requirement == AppUpdateRequirement.force;
  bool get isOptional => requirement == AppUpdateRequirement.optional;
}

/// Pure version-policy evaluator used by the global update coordinator.
///
/// It deliberately owns no dialog route. A force update is rendered by
/// AppUpdateGate above the app Navigator so route replacement after Splash,
/// Login or Home can never remove the blocking UI.
class AppRequirementGateService {
  AppRequirementGateService._();

  static final AppRequirementGateService instance =
      AppRequirementGateService._();

  Future<AppUpdateEvaluation?> evaluatePolicy(AppUpdatePolicy policy) async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;

    final platformPolicy = Platform.isAndroid ? policy.android : policy.ios;
    final current = Version.parse(await Utils.version());

    if (!platformPolicy.isConfigured) {
      logInfo(
        '[REQUIREMENT_GATE] platform=${Platform.operatingSystem} '
        'current=$current policy=disabled-or-empty',
      );
      return AppUpdateEvaluation(
        requirement: AppUpdateRequirement.allowed,
        platformPolicy: platformPolicy,
        currentVersion: current,
      );
    }

    final minimum = _parseVersion(platformPolicy.minimumVersion);
    final latest = _parseVersion(platformPolicy.latestVersion);

    if (minimum != null && latest != null && minimum > latest) {
      logError(
        '[REQUIREMENT_GATE] invalid policy: minimum=$minimum latest=$latest',
      );
      return AppUpdateEvaluation(
        requirement: AppUpdateRequirement.allowed,
        platformPolicy: platformPolicy,
        currentVersion: current,
        minimumVersion: minimum,
        latestVersion: latest,
      );
    }

    final forceUpdate = minimum != null && current < minimum;
    final optionalUpdate = !forceUpdate && latest != null && current < latest;

    final requirement = forceUpdate
        ? AppUpdateRequirement.force
        : optionalUpdate
            ? AppUpdateRequirement.optional
            : AppUpdateRequirement.allowed;

    logInfo(
      '[REQUIREMENT_GATE] platform=${Platform.operatingSystem} '
      'current=$current minimum=$minimum latest=$latest '
      'force=$forceUpdate optional=$optionalUpdate',
    );

    return AppUpdateEvaluation(
      requirement: requirement,
      platformPolicy: platformPolicy,
      currentVersion: current,
      minimumVersion: minimum,
      latestVersion: latest,
    );
  }

  Future<bool> openStore(AppUpdatePlatformPolicy policy) async {
    final storeUri = _resolveStoreUri(policy.storeUrl);
    final launched = await launchUrl(
      storeUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      logError('[REQUIREMENT_GATE] cannot open store URL: $storeUri');
    }
    return launched;
  }

  Version? _parseVersion(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    try {
      return Version.parse(value);
    } catch (_) {
      logError('[REQUIREMENT_GATE] invalid version="$value"');
      return null;
    }
  }

  Uri _resolveStoreUri(String configuredUrl) {
    final uri = Uri.tryParse(configuredUrl.trim());
    if (uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return uri;
    }

    return Uri.parse(
      Platform.isAndroid ? Utils.androidStoreUrl : Utils.iosStoreUrl,
    );
  }
}
