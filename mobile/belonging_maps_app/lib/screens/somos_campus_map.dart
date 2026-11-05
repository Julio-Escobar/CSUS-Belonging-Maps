import 'dart:async';

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

import '/models/somos_campus_resource.dart';
import '/services/accessibility_theme.dart';
import '/services/current_location.dart';
import '/services/latine_art_locations.dart';
import '/services/layer_search.dart';
import '/services/map_location_source.dart';
import '/services/somos_campus_resources.dart';
import '/widgets/current_location_buttons.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import '/widgets/map_filter_button.dart';
import '/widgets/map_location_browser.dart';
import '/widgets/map_search_bar.dart';
import '/widgets/search_suggestion_list.dart';

const String somosCampusBasemapUrl =
    'https://vectortileservices5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/services/CampusBasemapv3/VectorTileServer';
const String _openStreetMapBasemapUrl =
    'https://basemaps.arcgis.com/arcgis/rest/services/OpenStreetMap_v2/VectorTileServer';
const Color _somosMarkerColor = Color(0xFF2F5F3E);

// The art pin matches the numbered SOMOS markers, which are drawn at 30 px and
// enlarged to 42 px when selected (see `_markerSymbol`).
const double _latineArtIconSize = 30;
const double _selectedLatineArtIconSize = 42;
const double _campusLatitude = 38.56091;
const double _campusLongitude = -121.42405;
const double _campusScale = 8000;

// Padded campus bounds so the user cannot pan the campus completely away.
const double _campusExtentXMin = -121.4315;
const double _campusExtentYMin = 38.5495;
const double _campusExtentXMax = -121.4105;
const double _campusExtentYMax = 38.5690;

class SomosCampusMap extends StatefulWidget {
  const SomosCampusMap({super.key});

  @override
  State<SomosCampusMap> createState() => _SomosCampusMapState();
}

class _SomosCampusMapState extends State<SomosCampusMap> {
  late final ArcGISMap _map;
  late final ArcGISMapViewController _mapController;
  late final FeatureLayer _latineArtLayer;
  final TextEditingController _searchController = TextEditingController();
  final GraphicsOverlay _userOverlay = GraphicsOverlay();
  final GraphicsOverlay _resourcesOverlay = GraphicsOverlay();
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();
  final Map<String, CompositeSymbol> _markerSymbolCache = {};

  /// The Latine art locations cached once the feature layer has loaded, so they
  /// can be searched and browsed like the bundled campus resources.
  final List<MapLocation> _latineArtLocations = [];
  ArcGISImage? _latineArtIconImage;

  /// Increments on every search so slower, out-of-date layer queries cannot
  /// overwrite the definition expression for the latest query.
  int _latineArtSearchRequest = 0;

  List<SomosCampusResource> _resources = const [];
  Map<String, dynamic>? _selectedAttributes;
  double? _selectedLat;
  double? _selectedLng;
  bool _showFullInfo = false;
  bool _showInfoCard = false;

  /// Whether the selected location comes from the Latine art layer. Those
  /// cards are a fixed summary, while SOMOS resources keep the expandable card.
  bool _selectedIsLatineArt = false;
  bool _isLoading = true;
  bool _loadFailed = false;
  String _searchQuery = '';
  Set<String> _selectedCategories = const <String>{};
  bool _showSearchSuggestions = true;

  List<SomosCampusResource> get _visibleResources => filterSomosCampusResources(
    _resources,
    query: _searchQuery,
    categories: _selectedCategories,
  );

  /// Suggestions for the current query: the bundled SOMOS resources first, then
  /// the Latine art locations that match the search and category filter.
  List<SearchSuggestion> get _searchSuggestions {
    if (_searchQuery.isEmpty || !_showSearchSuggestions) return const [];

    return <SearchSuggestion>[
      ..._visibleResources
          .take(5)
          .map(
            (resource) => SearchSuggestion(
              title: resource.name,
              subtitle: resource.locationLabel,
              onSelected: () {
                _selectSearchSuggestion(resource);
              },
            ),
          ),
      ...filterLatineArtLocations(
        _latineArtLocations,
        query: _searchQuery,
        categories: _selectedCategories,
      ).map(
        (location) => SearchSuggestion(
          title: location.name,
          subtitle: latineArtCategory,
          onSelected: () {
            _selectLatineArtSuggestion(location);
          },
        ),
      ),
    ].take(5).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();

    final openStreetMapLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(_openStreetMapBasemapUrl),
    );
    final campusBasemapLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(somosCampusBasemapUrl),
    );

    // The campus vector tiles draw on top of the global OpenStreetMap basemap.
    _map =
        ArcGISMap.withBasemap(
            Basemap.withLayers(
              baseLayers: [openStreetMapLayer, campusBasemapLayer],
              referenceLayers: const [],
            ),
          )
          ..initialViewpoint = Viewpoint.withLatLongScale(
            latitude: _campusLatitude,
            longitude: _campusLongitude,
            scale: _campusScale,
          )
          ..maxExtent = Envelope.fromXY(
            xMin: _campusExtentXMin,
            yMin: _campusExtentYMin,
            xMax: _campusExtentXMax,
            yMax: _campusExtentYMax,
            spatialReference: SpatialReference.wgs84,
          );

    // Start with a visible fallback marker while the art pin loads.
    _latineArtLayer =
        FeatureLayer.withFeatureTable(
            ServiceFeatureTable.withUri(Uri.parse(sacStateLatineArtLayerUrl)),
          )
          ..renderer = SimpleRenderer(
            symbol: SimpleMarkerSymbol(
              style: SimpleMarkerSymbolStyle.circle,
              color: _somosMarkerColor,
              size: _latineArtIconSize,
            )..outline = SimpleLineSymbol(color: Colors.white, width: 2),
          );
    _map.operationalLayers.add(_latineArtLayer);

    _mapController = ArcGISMapView.createController()..arcGISMap = _map;
    _mapController.graphicsOverlays.addAll([
      _userOverlay,
      _resourcesOverlay,
      _selectionOverlay,
    ]);
    unawaited(_applyLatineArtIcon());
    _loadMapData();
  }

  /// Loads the Latine art pin from the bundled asset and draws it for every art
  /// location, replacing the plain circle marker used while it loads.
  Future<void> _applyLatineArtIcon() async {
    try {
      final image = await ArcGISImage.fromAsset(latineArtIconAsset);

      if (!mounted) return;
      _latineArtIconImage = image;
      _latineArtLayer.renderer = SimpleRenderer(
        symbol: _latineArtMarkerSymbol(image, _latineArtIconSize),
      );
    } catch (error) {
      // Keep the fallback circle marker if the icon cannot be loaded.
      debugPrint('Failed to load the Latine art location pin: $error');
    }
  }

  PictureMarkerSymbol _latineArtMarkerSymbol(ArcGISImage image, double size) {
    return PictureMarkerSymbol.withImage(image)
      ..width = size
      ..height = size;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads the configured resource dataset and the map. A failure puts the
  /// screen into an error state where the user can retry or return to the
  /// campus maps directory.
  Future<void> _loadMapData({bool retry = false}) async {
    if (!_isLoading || _loadFailed) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }

    try {
      final resources = await loadSomosCampusResources();

      if (retry && _map.loadStatus == LoadStatus.failedToLoad) {
        await _map.retryLoad();
      } else {
        await _map.load();
      }

      await _loadLatineArtLayer(retry: retry);

      if (!mounted) return;

      setState(() {
        _resources = resources;
        _isLoading = false;
      });
      _refreshResourceMarkers();
    } catch (error) {
      debugPrint('Failed to load the SOMOS campus resources: $error');
      if (!mounted) return;

      _resourcesOverlay.graphics.clear();
      _selectionOverlay.graphics.clear();
      setState(() {
        _resources = const [];
        _latineArtLocations.clear();
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  /// Loads the Latine art feature layer and caches its locations for search and
  /// browsing. A failure is logged instead of failing the whole screen, because
  /// the bundled SOMOS campus resources are still usable without the art layer.
  Future<void> _loadLatineArtLayer({bool retry = false}) async {
    try {
      if (retry && _latineArtLayer.loadStatus == LoadStatus.failedToLoad) {
        await _latineArtLayer.retryLoad();
      } else {
        await _latineArtLayer.load();
      }

      await _cacheLatineArtLocations();
    } catch (error) {
      debugPrint('Failed to load the SacStateLatineArt locations: $error');
    }
  }

  /// Caches every published art location in pages, so search suggestions and
  /// the Browse locations list stay complete as the layer grows.
  Future<void> _cacheLatineArtLocations() async {
    final table = _latineArtLayer.featureTable;
    if (table is! ServiceFeatureTable) return;

    final locations = <MapLocation>[];
    var offset = 0;
    while (true) {
      final query = QueryParameters()
        ..whereClause = '1=1'
        ..returnGeometry = true
        ..maxFeatures = mapLocationPageSize
        ..resultOffset = offset;
      final result = await table.queryFeaturesWithFieldOptions(
        parameters: query,
        queryFeatureFields: QueryFeatureFields.loadAll,
      );
      final features = result.features().toList();
      locations.addAll(
        features.map(
          (feature) => MapLocation.fromAttributes(
            feature.attributes,
            category: latineArtCategory,
            geometry: feature.geometry,
          ),
        ),
      );

      if (features.length < mapLocationPageSize) break;
      offset += features.length;
    }

    if (!mounted) return;
    setState(() {
      _latineArtLocations
        ..clear()
        ..addAll(locations);
    });
  }

  void _onSearchChanged(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery == _searchQuery) return;

    setState(() {
      _searchQuery = normalizedQuery;
      _showSearchSuggestions = true;
    });
    _refreshResourceMarkers();
    unawaited(_applyLatineArtSearchClause());
  }

  /// Keeps the Latine art pins in sync with the search box, so art locations
  /// whose name does not match the current query are hidden just like the
  /// bundled campus markers.
  Future<void> _applyLatineArtSearchClause() async {
    final query = _searchQuery;
    final request = ++_latineArtSearchRequest;

    // The clause depends on the layer's field list, so it can only be built
    // once the layer has loaded.
    if (_latineArtLayer.loadStatus != LoadStatus.loaded) return;

    try {
      final clause = await buildLayerSearchClause(_latineArtLayer, query);
      if (!mounted || request != _latineArtSearchRequest) return;
      _latineArtLayer.definitionExpression = clause;
    } catch (error) {
      debugPrint('Failed to search the Latine art locations: $error');
    }
  }

  void _onCategoryFilterChanged(String expression) {
    final categories = parseCategoryFilterExpression(expression);
    if (categories.length == _selectedCategories.length &&
        categories.containsAll(_selectedCategories)) {
      return;
    }

    setState(() => _selectedCategories = categories);
    _refreshResourceMarkers();
  }

  void _refreshResourceMarkers() {
    if (_selectedAttributes != null) {
      _dismissLocationCard();
    }
    _renderResourceMarkers();
    _updateLatineArtVisibility();
  }

  /// Hides the Latine art pins when the category filter excludes them, so the
  /// filter behaves the same way for every marker on the map.
  void _updateLatineArtVisibility() {
    _latineArtLayer.isVisible =
        _selectedCategories.isEmpty ||
        _selectedCategories.contains(latineArtCategory);
  }

  void _renderResourceMarkers() {
    _resourcesOverlay.graphics.clear();
    _selectionOverlay.graphics.clear();

    final visibleResources = _visibleResources;

    for (final resource in visibleResources) {
      final point = ArcGISPoint(
        x: resource.longitude,
        y: resource.latitude,
        spatialReference: SpatialReference.wgs84,
      );

      _resourcesOverlay.graphics.add(
        Graphic(
          geometry: point,
          attributes: resource.toAttributes(),
          symbol: _markerSymbol(resource.number),
        ),
      );
    }
  }

  CompositeSymbol _markerSymbol(int number, {double size = 30}) {
    final cacheKey = '$number@$size';
    final cached = _markerSymbolCache[cacheKey];
    if (cached != null) return cached;

    final circle = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle,
      color: _somosMarkerColor,
      size: size,
    )..outline = SimpleLineSymbol(color: Colors.white, width: 2);

    final label = TextSymbol(
      text: '$number',
      color: Colors.white,
      size: size * 0.46,
      horizontalAlignment: HorizontalAlignment.center,
      verticalAlignment: VerticalAlignment.middle,
    );

    final symbol = CompositeSymbol(symbols: [circle, label]);
    _markerSymbolCache[cacheKey] = symbol;
    return symbol;
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    if (_isLoading || _loadFailed) return;

    try {
      final result = await _mapController.identifyGraphicsOverlay(
        _resourcesOverlay,
        screenPoint: screenPoint,
        tolerance: 22.0,
        maximumResults: 1,
      );

      if (!mounted) return;

      // Numbered SOMOS markers are drawn in an overlay, so they take precedence
      // over the Latine art locations drawn underneath them.
      final graphic = result.graphics.firstOrNull;
      final attributes = graphic?.attributes;
      if (graphic != null && attributes != null && attributes.isNotEmpty) {
        _selectResource(graphic, attributes);
        return;
      }

      final artResult = await _mapController.identifyLayer(
        _latineArtLayer,
        screenPoint: screenPoint,
        tolerance: 22.0,
        maximumResults: 1,
      );

      if (!mounted) return;

      final artElement = artResult.geoElements.firstOrNull;
      if (artElement == null || artElement.attributes.isEmpty) {
        _dismissLocationCard();
        return;
      }

      await _showLatineArtOnMap(artElement.attributes, artElement.geometry);
    } catch (error) {
      debugPrint('Failed to identify a SOMOS campus resource: $error');
    }
  }

  /// Shows the info card for a tapped bundled resource and enlarges its marker.
  void _selectResource(Graphic graphic, Map<String, dynamic> attributes) {
    final number = attributes['NUMBER'];
    setState(() {
      _selectedAttributes = attributes;
      _selectedLat = _toDouble(attributes['LATITUDE']);
      _selectedLng = _toDouble(attributes['LONGITUDE']);
      _showFullInfo = false;
      _selectedIsLatineArt = false;
      _showInfoCard = true;
    });

    _selectionOverlay.graphics.clear();
    if (number is int) {
      _selectionOverlay.graphics.add(
        Graphic(
          geometry: graphic.geometry,
          attributes: attributes,
          symbol: _markerSymbol(number, size: 42),
        ),
      );
    }
  }

  /// Shows the info card for a Latine art location, draws the enlarged pin over
  /// it, and optionally recenters the map (used when browsing or searching).
  Future<void> _showLatineArtOnMap(
    Map<String, dynamic> attributes,
    Geometry? geometry, {
    double? scale,
  }) async {
    final point = latineArtWgs84Point(geometry);

    setState(() {
      _selectedAttributes = latineArtLocationAttributes(
        attributes,
        latitude: point?.y,
        longitude: point?.x,
      );
      _selectedLat = point?.y;
      _selectedLng = point?.x;
      _showFullInfo = false;
      _selectedIsLatineArt = true;
      _showInfoCard = true;
    });

    _selectionOverlay.graphics.clear();
    if (point == null) return;

    final image = _latineArtIconImage;
    final ArcGISSymbol symbol;
    if (image != null) {
      symbol = _latineArtMarkerSymbol(image, _selectedLatineArtIconSize);
    } else {
      symbol = SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: _somosMarkerColor,
        size: _selectedLatineArtIconSize,
      )..outline = SimpleLineSymbol(color: Colors.white, width: 2);
    }
    _selectionOverlay.graphics.add(Graphic(geometry: point, symbol: symbol));

    if (scale == null) {
      await _mapController.setViewpointCenter(point);
    } else {
      await _mapController.setViewpointCenter(point, scale: scale);
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _getCurrentLocation() {
    return showCurrentLocation(_mapController, _userOverlay);
  }

  Future<void> _browseLocations() async {
    if (_resources.isEmpty && _latineArtLocations.isEmpty) return;

    final visibleResources = _visibleResources;
    final visibleLatineArtLocations = filterLatineArtLocations(
      _latineArtLocations,
      query: _searchQuery,
      categories: _selectedCategories,
    );

    final location = await showMapLocationBrowser(context, [
      MapLocationSource(
        name: 'Campus locations',
        loadPage: (offset) async {
          final locations = visibleResources
              .skip(offset)
              .take(mapLocationPageSize)
              .map(
                (resource) => MapLocation.fromAttributes(
                  resource.toAttributes(),
                  category: resource.category,
                ),
              )
              .toList(growable: false);
          return MapLocationPage(
            locations,
            hasMore: offset + locations.length < visibleResources.length,
          );
        },
      ),
      if (visibleLatineArtLocations.isNotEmpty)
        MapLocationSource(
          name: latineArtCategory,
          loadPage: (offset) async {
            final locations = visibleLatineArtLocations
                .skip(offset)
                .take(mapLocationPageSize)
                .toList(growable: false);
            return MapLocationPage(
              locations,
              hasMore:
                  offset + locations.length < visibleLatineArtLocations.length,
            );
          },
        ),
    ]);
    if (!mounted || location == null) return;

    if (location.category == latineArtCategory) {
      await _showLatineArtOnMap(
        location.attributes,
        location.geometry,
        scale: 5000,
      );
      return;
    }

    final number = location.attributes['NUMBER']?.toString();
    for (final resource in _resources) {
      if (resource.number.toString() == number) {
        await _showResourceOnMap(resource);
        return;
      }
    }
  }

  Future<void> _showResourceOnMap(SomosCampusResource resource) async {
    final attributes = resource.toAttributes();
    final point = ArcGISPoint(
      x: resource.longitude,
      y: resource.latitude,
      spatialReference: SpatialReference.wgs84,
    );

    setState(() {
      _selectedAttributes = attributes;
      _selectedLat = resource.latitude;
      _selectedLng = resource.longitude;
      _showFullInfo = false;
      _selectedIsLatineArt = false;
      _showInfoCard = true;
    });

    _selectionOverlay.graphics.clear();
    _selectionOverlay.graphics.add(
      Graphic(
        geometry: point,
        attributes: attributes,
        symbol: _markerSymbol(resource.number, size: 42),
      ),
    );

    await _mapController.setViewpointCenter(point, scale: 5000);
  }

  Future<void> _selectSearchSuggestion(SomosCampusResource resource) async {
    _searchController.text = resource.name;
    setState(() {
      _searchQuery = resource.name;
      _showSearchSuggestions = false;
    });
    _renderResourceMarkers();
    await _showResourceOnMap(resource);
  }

  Future<void> _selectLatineArtSuggestion(MapLocation location) async {
    _searchController.text = location.name;
    setState(() {
      _searchQuery = location.name;
      _showSearchSuggestions = false;
    });
    _renderResourceMarkers();
    unawaited(_applyLatineArtSearchClause());
    await _showLatineArtOnMap(
      location.attributes,
      location.geometry,
      scale: 5000,
    );
  }

  Future<void> _zoomIn() async {
    final currentScale = _mapController.scale;
    if (currentScale.isNaN) return;
    await _mapController.setViewpointScale(currentScale / 2);
  }

  Future<void> _zoomOut() async {
    final currentScale = _mapController.scale;
    if (currentScale.isNaN) return;
    await _mapController.setViewpointScale(currentScale * 2);
  }

  void _dismissLocationCard() {
    if (_selectedAttributes == null) return;

    _selectionOverlay.graphics.clear();

    setState(() {
      _showInfoCard = false;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        _selectedAttributes = null;
        _selectedLat = null;
        _selectedLng = null;
        _showFullInfo = false;
        _selectedIsLatineArt = false;
      });
    });
  }

  String _cleanField(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    if (text.toLowerCase() == 'n/a') return '';
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  LocationInfoData _buildLocationInfoData() {
    final attributes = _selectedAttributes;
    final resourceName = _cleanField(attributes?['NAME']);
    final imageAsset = _cleanField(attributes?['IMAGE_ASSET']);

    return LocationInfoData(
      cardTitle: resourceName.isNotEmpty
          ? resourceName
          : 'SOMOS Campus Resource',
      address: _cleanField(attributes?['ADDRESS']),
      category: _cleanField(attributes?['CATEGORY']),
      type: _cleanField(attributes?['TYPE']),
      website: _cleanField(attributes?['WEBSITE']),
      phone: _cleanField(attributes?['PHONE']),
      email: _cleanField(attributes?['EMAIL']),
      description: _cleanField(attributes?['DESCRIPTION']),
      imageUrl: null,
      imageAsset: imageAsset.isEmpty ? null : imageAsset,
      socialLinks: const {},
      locationLat: _selectedLat,
      locationLng: _selectedLng,
      orgLogo: 'assets/somos_logo_temp.png',
    );
  }

  Widget _buildLocationInfoCard() {
    final data = _buildLocationInfoData();

    return LocationInfoCard(
      data: data,
      // Latine art cards are a fixed summary, so they never expand.
      showFullInfo: _selectedIsLatineArt ? false : _showFullInfo,
      summaryOnly: _selectedIsLatineArt,
      onClose: _dismissLocationCard,
      onShowMore: () {
        setState(() {
          _showFullInfo = true;
        });
      },
      onShowLess: () {
        setState(() {
          _showFullInfo = false;
        });
      },
    );
  }

  Widget _buildAnimatedLocationInfoCard() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      offset: _showInfoCard ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showInfoCard ? 1 : 0,
        child: _buildLocationInfoCard(),
      ),
    );
  }

  Widget _buildTopMapControls() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            const SizedBox(width: 12),
            Expanded(
              child: MapSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                suggestions: _searchSuggestions,
              ),
            ),
            if (_resources.isNotEmpty) ...[
              const SizedBox(width: 12),
              MapFilterButton(
                key: ValueKey<int>(_resources.length),
                featureLayer: null,
                filterField: 'CATEGORY',
                label: 'Category',
                loadFilters: () async {
                  final categories = somosCampusResourceCategories(
                    _resources,
                  ).toSet()..add(latineArtCategory);
                  return categories.toList()..sort();
                },
                onDefinitionExpressionChanged: _onCategoryFilterChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return HamburgerMenu(
      title: 'SOMOS Campus Map',
      body: Scaffold(
        backgroundColor: colors.pageBackground,
        body: _loadFailed
            ? _buildErrorState(context)
            : Stack(
                children: [
                  ArcGISMapView(
                    controllerProvider: () => _mapController,
                    onTap: _handleMapTap,
                  ),
                  MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
                  _buildTopMapControls(),
                  CurrentLocationButton(onPressed: _getCurrentLocation),
                  if (_resources.isNotEmpty && _selectedAttributes == null)
                    Positioned(
                      bottom: 24,
                      left: 16,
                      child: SafeArea(
                        child: ElevatedButton.icon(
                          onPressed: _browseLocations,
                          icon: const Icon(Icons.list),
                          label: const Text('Browse locations'),
                        ),
                      ),
                    ),
                  if (_isLoading)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    ),
                  if (_selectedAttributes != null && !_isLoading)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _dismissLocationCard,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  if (_selectedAttributes != null && !_isLoading)
                    _buildAnimatedLocationInfoCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 56, color: colors.primary),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                'Unable to load the map',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "The SOMOS campus resources couldn't be loaded. "
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadMapData(retry: true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Try Again', textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Back to Campus Maps',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
