import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/favorites_store.dart';
import '../widgets/favorite_toggle_button.dart';
import '../widgets/location_info_card.dart';
import 'opportunities.dart';

class FavoritesScreen extends StatefulWidget {
  final http.Client? opportunitiesClient;

  const FavoritesScreen({super.key, this.opportunitiesClient});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesStore _store = FavoritesStore.instance;
  List<FavoriteEntry> _favorites = const [];
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _store.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _store.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final favorites = await _store.loadFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  void _openFavorite(FavoriteEntry favorite) {
    if (favorite.type == FavoriteType.opportunity) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OpportunitiesScreen(
            client: widget.opportunitiesClient,
            initialOpportunityId: favorite.id,
          ),
        ),
      );
      return;
    }

    try {
      final data = LocationInfoData.fromFavoriteJson(favorite.data);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LocationFavoriteDetailsScreen(data: data),
        ),
      );
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This saved location is unavailable.')),
      );
    } on TypeError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This saved location is unavailable.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Favorites could not be loaded.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _reload();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            )
          : _favorites.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label:
                      'No favorites yet. Save a location or opportunity using its star button.',
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_border, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No favorites yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Save a location or opportunity with its star button, '
                          'and it will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final favorite = _favorites[index];
                final typeLabel = favorite.type == FavoriteType.location
                    ? 'Location'
                    : 'Opportunity';
                return Card(
                  child: ListTile(
                    leading: Icon(
                      favorite.type == FavoriteType.location
                          ? Icons.place_outlined
                          : Icons.school_outlined,
                    ),
                    title: Text(favorite.title),
                    subtitle: Text(typeLabel),
                    onTap: () => _openFavorite(favorite),
                    trailing: FavoriteToggleButton(
                      favorite: favorite,
                      onChanged: (isFavorite) {
                        if (!isFavorite && mounted) {
                          setState(() {
                            _favorites = List.of(_favorites)
                              ..removeWhere(
                                (entry) =>
                                    entry.type == favorite.type &&
                                    entry.id == favorite.id,
                              );
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class LocationFavoriteDetailsScreen extends StatelessWidget {
  final LocationInfoData data;

  const LocationFavoriteDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location details')),
      body: LocationInfoCard(
        data: data,
        showFullInfo: true,
        onClose: () => Navigator.of(context).maybePop(),
        onShowMore: () {},
        onShowLess: () {},
      ),
    );
  }
}
