import 'package:belonging_maps_app/screens/favorites_screen.dart';
import 'package:belonging_maps_app/screens/opportunities.dart';
import 'package:belonging_maps_app/services/favorites_store.dart';
import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty favorites state is accessible', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: FavoritesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No favorites yet'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'No favorites yet. Save a location or opportunity using its star button.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('favorite toggles, survives reopening, and opens location', (
    tester,
  ) async {
    final data = LocationInfoData(
      id: 'student-center-42',
      cardTitle: 'Student Center',
      address: '6000 J Street',
      category: 'Campus Centers',
      type: 'Student services',
      website: '',
      phone: '',
      email: '',
      description: 'A place for students.',
      imageUrl: null,
      socialLinks: const {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationInfoCard(
            data: data,
            showFullInfo: true,
            onClose: () {},
            onShowMore: () {},
            onShowLess: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add Student Center to favorites'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Student Center to favorites'));
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Remove Student Center from favorites'),
      findsOneWidget,
    );

    await tester.pumpWidget(const MaterialApp(home: FavoritesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Student Center'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(const MaterialApp(home: FavoritesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Student Center'));
    await tester.pumpAndSettle();

    expect(find.text('Location details'), findsOneWidget);
    expect(find.text('Type: Student services'), findsOneWidget);
    expect(find.text('A place for students.'), findsOneWidget);
  });

  testWidgets('saved location can be removed from Favorites', (tester) async {
    await FavoritesStore.instance.save(
      const FavoriteEntry(
        type: FavoriteType.location,
        id: 'remove-me',
        title: 'Removable location',
        data: {
          'cardTitle': 'Removable location',
          'address': '',
          'category': '',
          'type': '',
          'website': '',
          'phone': '',
          'email': '',
          'description': '',
          'socialLinks': {},
        },
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: FavoritesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip('Remove Removable location from favorites'),
    );
    await tester.pumpAndSettle();

    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets(
    'unavailable saved location shows a message instead of crashing',
    (tester) async {
      await FavoritesStore.instance.save(
        const FavoriteEntry(
          type: FavoriteType.location,
          id: 'unavailable',
          title: 'Unavailable location',
          data: {},
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: FavoritesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unavailable location'));
      await tester.pumpAndSettle();

      expect(find.text('This saved location is unavailable.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opportunity can be favorited and reopened from Favorites', (
    tester,
  ) async {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://example.test');
    final client = MockClient((request) async {
      return http.Response(
        '[{"id":7,"title":"Student Opportunity","category":"SOMOS",'
        '"description":"Current details","iconKey":"book","links":['
        '{"name":"Apply","url":"https://example.test/apply"}]}]',
        200,
      );
    });
    addTearDown(client.close);

    await tester.pumpWidget(
      MaterialApp(home: OpportunitiesScreen(client: client)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Student Opportunity to favorites'));
    await tester.pumpAndSettle();
    expect(
      await FavoritesStore.instance.contains(FavoriteType.opportunity, '7'),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(home: FavoritesScreen(opportunitiesClient: client)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Student Opportunity'), findsOneWidget);

    await tester.tap(find.text('Student Opportunity'));
    await tester.pumpAndSettle();
    expect(find.text('Current details'), findsNWidgets(2));
    expect(find.text('Apply'), findsOneWidget);
  });
}
