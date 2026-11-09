import 'package:belonging_maps_app/services/favorites_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists favorites across store reads', () async {
    final store = FavoritesStore.instance;
    const favorite = FavoriteEntry(
      type: FavoriteType.location,
      id: 'location-42',
      title: 'Student Center',
      data: {'cardTitle': 'Student Center'},
    );

    await store.save(favorite);

    expect(
      (await store.loadFavorites()).map((entry) => entry.toJson()).toList(),
      [favorite.toJson()],
    );
  });

  test('saving an existing typed ID updates it without duplication', () async {
    final store = FavoritesStore.instance;
    const original = FavoriteEntry(
      type: FavoriteType.location,
      id: '42',
      title: 'Old name',
      data: {'cardTitle': 'Old name'},
    );
    const updated = FavoriteEntry(
      type: FavoriteType.location,
      id: '42',
      title: 'Current name',
      data: {'cardTitle': 'Current name'},
    );

    await store.save(original);
    await store.save(updated);

    expect(
      (await store.loadFavorites()).map((entry) => entry.toJson()).toList(),
      [updated.toJson()],
    );
  });

  test('location and opportunity IDs are stored separately', () async {
    final store = FavoritesStore.instance;
    const location = FavoriteEntry(
      type: FavoriteType.location,
      id: '42',
      title: 'Location 42',
      data: {'cardTitle': 'Location 42'},
    );
    const opportunity = FavoriteEntry(
      type: FavoriteType.opportunity,
      id: '42',
      title: 'Opportunity 42',
      data: {'title': 'Opportunity 42'},
    );

    await store.save(location);
    await store.save(opportunity);

    expect(
      (await store.loadFavorites()).map((entry) => entry.toJson()).toList(),
      [location.toJson(), opportunity.toJson()],
    );
  });

  test('removal only removes the matching type and ID', () async {
    final store = FavoritesStore.instance;
    const location = FavoriteEntry(
      type: FavoriteType.location,
      id: '42',
      title: 'Location 42',
      data: {'cardTitle': 'Location 42'},
    );
    const opportunity = FavoriteEntry(
      type: FavoriteType.opportunity,
      id: '42',
      title: 'Opportunity 42',
      data: {'title': 'Opportunity 42'},
    );
    await store.save(location);
    await store.save(opportunity);

    await store.remove(FavoriteType.location, '42');

    expect(
      (await store.loadFavorites()).map((entry) => entry.toJson()).toList(),
      [opportunity.toJson()],
    );
  });
}
