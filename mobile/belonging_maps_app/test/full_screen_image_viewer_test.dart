import 'package:belonging_maps_app/widgets/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pushes the viewer from a host screen, so the tests can check that it opens,
/// fills the screen, and pops back.
Future<void> _openViewer(
  WidgetTester tester, {
  String? assetPath = 'assets/somos_campus_map_art/UFW_Fountain.jpg',
  String? url,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => FullScreenImageViewer.show(
                context,
                assetPath: assetPath,
                url: url,
                semanticsLabel: 'Photo of UFW Fountain',
              ),
              child: const Text('Open photo'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open photo'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the photo fills the screen without being cropped', (
    tester,
  ) async {
    await _openViewer(tester);

    expect(find.byKey(fullScreenImageViewerKey), findsOneWidget);
    expect(find.byKey(fullScreenImageCloseKey), findsOneWidget);

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('the close button returns to the previous screen', (
    tester,
  ) async {
    await _openViewer(tester);

    await tester.tap(find.byKey(fullScreenImageCloseKey));
    await tester.pumpAndSettle();

    expect(find.byKey(fullScreenImageViewerKey), findsNothing);
    expect(find.text('Open photo'), findsOneWidget);
  });

  testWidgets('tapping the photo dismisses the viewer', (tester) async {
    await _openViewer(tester);

    await tester.tap(find.byKey(fullScreenImageViewerKey));
    await tester.pumpAndSettle();

    expect(find.byKey(fullScreenImageViewerKey), findsNothing);
    expect(find.text('Open photo'), findsOneWidget);
  });

  testWidgets('a location without a photo shows the fallback', (tester) async {
    await _openViewer(tester, assetPath: null);

    expect(find.byKey(fullScreenImageViewerKey), findsOneWidget);
    expect(find.text('Image unavailable'), findsOneWidget);
  });
}
