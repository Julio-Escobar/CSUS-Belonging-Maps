import 'package:package_info_plus/package_info_plus.dart';

/// The installed app's version and build number (P1-321). Read at runtime
/// from the package metadata, which Flutter fills in from `pubspec.yaml`'s
/// `version: <semver>+<build>` line, so nobody has to edit a string in the
/// About Us screen for each release.
class AppVersion {
  final String version;
  final String buildNumber;

  const AppVersion({required this.version, required this.buildNumber});

  /// Text shown on About Us, e.g. `Version 1.1.0 (2)`.
  String get label {
    final build = buildNumber.trim();
    return build.isEmpty ? 'Version $version' : 'Version $version ($build)';
  }
}

/// Signature for anything that can look up the installed version. Screens
/// take one of these so tests can pass a fake instead of the platform plugin.
typedef AppVersionLoader = Future<AppVersion> Function();

/// Default loader backed by package_info_plus.
Future<AppVersion> loadInstalledAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return AppVersion(version: info.version, buildNumber: info.buildNumber);
}
