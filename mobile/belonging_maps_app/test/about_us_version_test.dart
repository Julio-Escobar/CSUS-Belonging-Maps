import 'package:belonging_maps_app/screens/about_us_screen.dart';
import 'package:belonging_maps_app/services/app_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

// P1-323: About Us shows the installed version instead of a hard-coded one.
void main() {
  group('AppVersion.label', () {
    test('formats version and build number', () {
      const version = AppVersion(version: '1.1.0', buildNumber: '2');
      expect(version.label, 'Version 1.1.0 (2)');
    });

    test('leaves out empty build numbers', () {
      const version = AppVersion(version: '1.1.0', buildNumber: ' ');
      expect(version.label, 'Version 1.1.0');
    });
  });

  test('loadInstalledAppVersion reads the package metadata', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Belonging Maps',
      packageName: 'edu.csus.belonging_maps_app',
      version: '1.1.0',
      buildNumber: '2',
      buildSignature: '',
    );

    final version = await loadInstalledAppVersion();
    expect(version.label, 'Version 1.1.0 (2)');
  });

  Future<void> pumpAboutUs(WidgetTester tester, AppVersionLoader loader) {
    return tester.pumpWidget(
      MaterialApp(home: AboutUsScreen(versionLoader: loader)),
    );
  }

  testWidgets('shows the runtime version once it loads', (tester) async {
    await pumpAboutUs(
      tester,
      () async => const AppVersion(version: '1.1.0', buildNumber: '2'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version 1.1.0 (2)'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsNothing);
  });

  testWidgets('keeps the page usable while the version loads', (tester) async {
    final pending = Future<AppVersion>.delayed(
      const Duration(seconds: 1),
      () => const AppVersion(version: '1.1.0', buildNumber: '2'),
    );
    await pumpAboutUs(tester, () => pending);

    expect(find.text('Belonging Maps'), findsOneWidget);
    final placeholderHeight = tester
        .getSize(find.byKey(const Key('aboutUsVersion')))
        .height;

    await tester.pump(const Duration(seconds: 1));
    final loadedHeight = tester
        .getSize(find.byKey(const Key('aboutUsVersion')))
        .height;
    expect(find.text('Version 1.1.0 (2)'), findsOneWidget);
    expect(loadedHeight, placeholderHeight);
  });

  testWidgets('shows a fallback instead of crashing on errors', (tester) async {
    await pumpAboutUs(tester, () async => throw StateError('no metadata'));
    await tester.pumpAndSettle();

    expect(find.text('Version unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
