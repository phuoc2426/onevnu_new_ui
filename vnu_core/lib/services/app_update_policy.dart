class AppUpdatePlatformPolicy {
  const AppUpdatePlatformPolicy({
    required this.enabled,
    required this.minimumVersion,
    required this.latestVersion,
    required this.storeUrl,
    required this.forceMessage,
    required this.optionalMessage,
  });

  final bool enabled;
  final String minimumVersion;
  final String latestVersion;
  final String storeUrl;
  final String forceMessage;
  final String optionalMessage;

  bool get isConfigured =>
      enabled &&
      (minimumVersion.trim().isNotEmpty || latestVersion.trim().isNotEmpty);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'enabled': enabled,
        'minimumVersion': minimumVersion,
        'latestVersion': latestVersion,
        'storeUrl': storeUrl,
        'forceMessage': forceMessage,
        'optionalMessage': optionalMessage,
      };

  factory AppUpdatePlatformPolicy.fromMap(Map<String, dynamic> map) {
    bool readBool(dynamic value) {
      if (value is bool) return value;
      return value?.toString().trim().toLowerCase() == 'true';
    }

    String readString(String key) => map[key]?.toString().trim() ?? '';

    return AppUpdatePlatformPolicy(
      enabled: readBool(map['enabled']),
      minimumVersion: readString('minimumVersion'),
      latestVersion: readString('latestVersion'),
      storeUrl: readString('storeUrl'),
      forceMessage: readString('forceMessage'),
      optionalMessage: readString('optionalMessage'),
    );
  }
}

class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.android,
    required this.ios,
  });

  final AppUpdatePlatformPolicy android;
  final AppUpdatePlatformPolicy ios;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'android': android.toMap(),
        'ios': ios.toMap(),
      };

  factory AppUpdatePolicy.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> child(String key) {
      final value = map[key];
      if (value is Map) return Map<String, dynamic>.from(value);
      return const <String, dynamic>{};
    }

    return AppUpdatePolicy(
      android: AppUpdatePlatformPolicy.fromMap(child('android')),
      ios: AppUpdatePlatformPolicy.fromMap(child('ios')),
    );
  }
}

