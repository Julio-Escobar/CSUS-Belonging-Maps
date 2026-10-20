import 'package:belonging_maps_app/models/somos_campus_resource.dart';
import 'package:belonging_maps_app/services/somos_campus_resources.dart';
import 'package:belonging_maps_app/widgets/somos_campus_resource_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildLauncher({
    required List<SomosCampusResource> resources,
    required ValueChanged<SomosCampusResource?> onSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final resource = await showSomosCampusResourceList(
                context,
                resources,
              );
              onSelected(resource);
            },
            child: const Text('Open list'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows numbered resources and returns the selected item', (
    tester,
  ) async {
    final resources = await loadSomosCampusResources();
    SomosCampusResource? selected;

    await tester.pumpWidget(
      buildLauncher(
        resources: resources,
        onSelected: (resource) => selected = resource,
      ),
    );

    await tester.tap(find.text('Open list'));
    await tester.pumpAndSettle();

    expect(find.text('SOMOS Campus Resources'), findsOneWidget);
    expect(find.text('1. Associated Students, Inc. (ASI)'), findsOneWidget);
    expect(find.text('University Union'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('17. Carlsen Center for Innovation & Entrepreneurship'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(
      find.text('17. Carlsen Center for Innovation & Entrepreneurship'),
      findsOneWidget,
    );
    expect(find.text('University Library, Room 1520'), findsOneWidget);

    await tester.tap(
      find.text('17. Carlsen Center for Innovation & Entrepreneurship'),
    );
    await tester.pumpAndSettle();

    expect(selected?.number, 17);
    expect(selected?.name, 'Carlsen Center for Innovation & Entrepreneurship');
  });

  testWidgets('shows an empty state when no resources are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildLauncher(resources: const [], onSelected: (_) {}),
    );

    await tester.tap(find.text('Open list'));
    await tester.pumpAndSettle();

    expect(find.text('SOMOS Campus Resources'), findsOneWidget);
    expect(find.text('No campus resources are available.'), findsOneWidget);
  });
}
