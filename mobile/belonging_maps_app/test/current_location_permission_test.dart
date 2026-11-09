import 'dart:io';

import 'package:belonging_maps_app/services/current_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

// P1-326: app-side permission handling for the current-location button.
// The real iOS prompt still has to be checked on a simulator or device.

class _FakePermissions {
  bool serviceEnabled = true;
  LocationPermission current = LocationPermission.denied;
  LocationPermission afterRequest = LocationPermission.whileInUse;
  int requests = 0;

  LocationPermissionApi get api => LocationPermissionApi(
    isServiceEnabled: () async => serviceEnabled,
    checkPermission: () async => current,
    requestPermission: () async {
      requests++;
      current = afterRequest;
      return afterRequest;
    },
  );
}

void main() {
  group('resolveLocationAccess', () {
    test('asks the first time and is granted when the person allows', () async {
      final fake = _FakePermissions();

      expect(await resolveLocationAccess(fake.api), LocationAccess.granted);
      expect(fake.requests, 1);
    });

    test('does not ask again once already granted', () async {
      final fake = _FakePermissions()..current = LocationPermission.whileInUse;

      expect(await resolveLocationAccess(fake.api), LocationAccess.granted);
      expect(fake.requests, 0);
    });

    test('treats "always" as granted', () async {
      final fake = _FakePermissions()..current = LocationPermission.always;

      expect(await resolveLocationAccess(fake.api), LocationAccess.granted);
    });

    test('reports denied and asks again on the next tap', () async {
      final fake = _FakePermissions()..afterRequest = LocationPermission.denied;

      expect(await resolveLocationAccess(fake.api), LocationAccess.denied);
      expect(await resolveLocationAccess(fake.api), LocationAccess.denied);
      expect(fake.requests, 2);
    });

    test('does not prompt when permanently denied', () async {
      final fake = _FakePermissions()
        ..current = LocationPermission.deniedForever;

      expect(
        await resolveLocationAccess(fake.api),
        LocationAccess.deniedForever,
      );
      expect(fake.requests, 0);
    });

    test('reports when the person picks "don\'t ask again"', () async {
      final fake = _FakePermissions()
        ..afterRequest = LocationPermission.deniedForever;

      expect(
        await resolveLocationAccess(fake.api),
        LocationAccess.deniedForever,
      );
    });

    test('stops early when location services are off', () async {
      final fake = _FakePermissions()..serviceEnabled = false;

      expect(
        await resolveLocationAccess(fake.api),
        LocationAccess.serviceDisabled,
      );
      expect(fake.requests, 0);
    });
  });

  group('locationAccessMessage', () {
    test('has no message when granted', () {
      expect(locationAccessMessage(LocationAccess.granted), isNull);
    });

    test('explains how to retry or fix every other state', () {
      expect(
        locationAccessMessage(LocationAccess.denied),
        contains('try again'),
      );
      expect(
        locationAccessMessage(LocationAccess.deniedForever),
        contains('Settings'),
      );
      expect(
        locationAccessMessage(LocationAccess.serviceDisabled),
        contains('Location services are off'),
      );
    });
  });

  testWidgets('permanently denied shows a Settings action and the map stays '
      'usable', (tester) async {
    var mapTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => showLocationAccessMessage(
                    context,
                    LocationAccess.deniedForever,
                  ),
                  child: const Text('Locate'),
                ),
                ElevatedButton(
                  onPressed: () => mapTapped = true,
                  child: const Text('Map'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Locate'));
    await tester.pump();
    expect(
      find.text(locationAccessMessage(LocationAccess.deniedForever)!),
      findsOneWidget,
    );
    expect(find.widgetWithText(SnackBarAction, 'Settings'), findsOneWidget);

    await tester.tap(find.text('Map'));
    expect(mapTapped, isTrue);
  });

  test('iOS Info.plist declares when-in-use location with purpose text', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final match = RegExp(
      r'<key>NSLocationWhenInUseUsageDescription</key>\s*<string>([^<]+)</string>',
    ).firstMatch(plist);

    expect(match, isNotNull);
    expect(match!.group(1)!.toLowerCase(), contains('location'));
  });
}
