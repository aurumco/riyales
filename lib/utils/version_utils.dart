import 'package:package_info_plus/package_info_plus.dart';

/// Utility class for version-related operations
class VersionUtils {
  /// Singleton instance
  static final VersionUtils _instance = VersionUtils._internal();

  /// Factory constructor
  factory VersionUtils() => _instance;

  /// Internal constructor
  VersionUtils._internal();

  /// Cached package info
  PackageInfo? _packageInfo;

  /// Initialize package info
  Future<PackageInfo> init() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  /// Get current app version
  Future<String> getCurrentVersion() async {
    final packageInfo = await init();
    return packageInfo.version;
  }

  /// Compare two semantic versions
  /// Returns:
  /// - positive number if v1 > v2
  /// - 0 if v1 == v2
  /// - negative number if v1 < v2
  int compareVersions(String v1, String v2) {
    final List<int> v1Parts = v1.split('.').map(int.parse).toList();
    final List<int> v2Parts = v2.split('.').map(int.parse).toList();

    // Ensure both lists have the same length
    final int maxLength =
        v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    while (v1Parts.length < maxLength) {
      v1Parts.add(0);
    }
    while (v2Parts.length < maxLength) {
      v2Parts.add(0);
    }

    // Compare each segment
    for (int i = 0; i < maxLength; i++) {
      final int diff = v1Parts[i] - v2Parts[i];
      if (diff != 0) return diff;
    }

    return 0; // Versions are equal
  }

  /// Check if an update is available
  /// Returns true if remoteVersion > currentVersion
  Future<bool> isUpdateAvailable(String remoteVersion) async {
    final currentVersion = await getCurrentVersion();
    return compareVersions(remoteVersion, currentVersion) > 0;
  }
}
