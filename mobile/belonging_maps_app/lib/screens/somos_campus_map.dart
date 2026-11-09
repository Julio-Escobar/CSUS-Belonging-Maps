import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

import '/models/somos_campus_center.dart';
import '/models/somos_campus_food.dart';
import '/models/somos_campus_resource.dart';
import '/services/accessibility_theme.dart';
import '/services/current_location.dart';
import '/services/latine_art_locations.dart';
import '/services/layer_search.dart';
import '/services/map_location_source.dart';
import '/services/somos_campus_centers.dart';
import '/services/somos_campus_food.dart';
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

/// Label-only "Light Gray Reference" vector tile style (ArcGIS item
/// a8416e7b45034be7b748071e10dde506, "LightGreyReferenceEdited"). Drawn above
/// the campus basemap tiles but below the SOMOS markers so building names stay
/// readable over the campus building footprints. The CampusBasemapv3 style has
/// no label layers of its own, so this is what supplies the building names.
const String somosCampusLabelsStyleUrl =
    'https://www.arcgis.com/sharing/rest/content/items/a8416e7b45034be7b748071e10dde506/resources/styles/root.json';

// The art pin matches the numbered SOMOS markers, which are drawn at 30 px and
// enlarged to 42 px when selected (see `_markerSymbol`).
const double _latineArtIconSize = 30;
const double _selectedLatineArtIconSize = 42;

// The campus center logos are drawn larger than the numbered markers so their
// wordmarks stay legible, and enlarged further when selected.
const double _centerIconSize = 40;
const double _selectedCenterIconSize = 56;

// The Latine food icons match the numbered markers, which are drawn at 30 px
// and enlarged to 42 px when selected (see `_markerSymbol`).
const double _foodIconSize = 30;
const double _selectedFoodIconSize = 42;
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
  final GraphicsOverlay _centersOverlay = GraphicsOverlay();
  final GraphicsOverlay _foodOverlay = GraphicsOverlay();
  final GraphicsOverlay _resourcesOverlay = GraphicsOverlay();
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();
  final Map<String, CompositeSymbol> _markerSymbolCache = {};

  /// Marker color from the active accessibility palette. Updated in
  /// [didChangeDependencies] so the pins follow the colorblind setting.
  Color _markerColor = AccessibilityColors.normal.primary;

  /// The Latine art locations cached once the feature layer has loaded, so they
  /// can be searched and browsed like the bundled campus resources.
  final List<MapLocation> _latineArtLocations = [];
  ArcGISImage? _latineArtIconImage;

  /// Increments on every search so slower, out-of-date layer queries cannot
  /// overwrite the definition expression for the latest query.
  int _latineArtSearchRequest = 0;

  List<SomosCampusResource> _resources = const [];
  List<SomosCampusCenter> _centers = const [];
  List<SomosCampusFood> _food = const [];
  final Map<String, ArcGISImage> _centerIconImages = {};
  final Map<String, ArcGISImage> _centerBackgroundImages = {};
  final Map<String, ArcGISImage> _foodIconImages = {};
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

  List<SomosCampusCenter> get _visibleCenters => filterSomosCampusCenters(
    _centers,
    query: _searchQuery,
    categories: _selectedCategories,
  );

  List<SomosCampusFood> get _visibleFood => filterSomosCampusFood(
    _food,
    query: _searchQuery,
    categories: _selectedCategories,
  );

  /// Suggestions for the current query: the bundled SOMOS resources and
  /// centers first, then the Latine food options and art locations that match
  /// the search and category filter.
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
      ..._visibleCenters
          .take(5)
          .map(
            (center) => SearchSuggestion(
              title: center.name,
              subtitle: center.locationLabel,
              onSelected: () {
                _selectCenterSuggestion(center);
              },
            ),
          ),
      ..._visibleFood
          .take(5)
          .map(
            (food) => SearchSuggestion(
              title: food.name,
              subtitle: food.locationLabel,
              onSelected: () {
                _selectFoodSuggestion(food);
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
    final campusLabelsLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(somosCampusLabelsStyleUrl),
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
              color: _markerColor,
              size: _latineArtIconSize,
            )..outline = SimpleLineSymbol(color: Colors.white, width: 2),
          );

    // The label tiles draw above the campus tiles but below the Latine art pins
    // so the building names stay readable and the markers stay on top.
    _map.operationalLayers.add(campusLabelsLayer);
    _map.operationalLayers.add(_latineArtLayer);

    _mapController = ArcGISMapView.createController()..arcGISMap = _map;
    _mapController.graphicsOverlays.addAll([
      _userOverlay,
      _centersOverlay,
      _foodOverlay,
      _resourcesOverlay,
      _selectionOverlay,
    ]);
    unawaited(_applyLatineArtIcon());
    _loadMapData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final color = AccessibilityColors.of(context).primary;
    if (color != _markerColor) {
      _markerColor = color;
      // Symbols and center backgrounds are cached with the old color.
      _markerSymbolCache.clear();
      _centerBackgroundImages.clear();
      if (!_isLoading) {
        _refreshResourceMarkers();
        unawaited(_loadCenterIcons());
      }
    }
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
      await _loadCampusCenters();
      await _loadCampusFood();
    } catch (error) {
      debugPrint('Failed to load the SOMOS campus resources: $error');
      if (!mounted) return;

      _centersOverlay.graphics.clear();
      _foodOverlay.graphics.clear();
      _resourcesOverlay.graphics.clear();
      _selectionOverlay.graphics.clear();
      setState(() {
        _resources = const [];
        _centers = const [];
        _food = const [];
        _latineArtLocations.clear();
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  /// Loads the SOMOS campus centers from the bundled dataset and draws their
  /// placeholder markers. A failure is logged instead of failing the whole
  /// screen, because the numbered resources and art locations still work.
  Future<void> _loadCampusCenters() async {
    try {
      final centers = await loadSomosCampusCenters();
      if (!mounted) return;

      setState(() {
        _centers = centers;
      });
      _renderCenterMarkers();
      unawaited(_loadCenterIcons());
    } catch (error) {
      debugPrint('Failed to load the SOMOS campus centers: $error');
    }
  }

  /// Loads the Latine food options from the bundled dataset and draws their
  /// markers. A failure is logged instead of failing the whole screen, because
  /// the numbered resources, centers, and art locations still work.
  Future<void> _loadCampusFood() async {
    try {
      final food = await loadSomosCampusFood();
      if (!mounted) return;

      setState(() {
        _food = food;
      });
      _renderFoodMarkers();
      unawaited(_loadFoodIcons());
    } catch (error) {
      debugPrint('Failed to load the Latine food options: $error');
    }
  }

  /// Loads the bundled icon for each distinct food marker and redraws them.
  /// Missing icons are skipped so the other markers still render.
  Future<void> _loadFoodIcons() async {
    final assets = <String>{for (final food in _food) food.iconAsset};

    for (final asset in assets) {
      try {
        final image = await ArcGISImage.fromAsset(asset);
        if (!mounted) return;
        _foodIconImages[asset] = image;
      } catch (error) {
        debugPrint('Failed to load the Latine food icon $asset: $error');
      }
    }

    if (!mounted) return;
    _renderFoodMarkers();
  }

  /// Loads the bundled icon for each distinct center marker and redraws them.
  /// Missing icons are skipped so the other centers still render.
  Future<void> _loadCenterIcons() async {
    final assets = <String>{
      SomosCampusCenter.placeholderIconAsset,
      for (final center in _centers) center.iconAsset,
    };

    for (final asset in assets) {
      try {
        final image = await ArcGISImage.fromAsset(asset);
        if (!mounted) return;
        _centerIconImages[asset] = image;
      } catch (error) {
        debugPrint(
          'Failed to load the SOMOS campus center icon $asset: $error',
        );
      }
    }

    final backgrounds = <String>{
      for (final center in _centers)
        if (_centerBackgroundColor(center.background) != null)
          center.background.trim(),
    };
    for (final token in backgrounds) {
      final color = _centerBackgroundColor(token);
      if (color == null || _centerBackgroundImages.containsKey(token)) {
        continue;
      }
      try {
        final image = await _solidColorImage(color);
        if (!mounted) return;
        if (image != null) _centerBackgroundImages[token] = image;
      } catch (error) {
        debugPrint('Failed to build the background "$token": $error');
      }
    }

    if (!mounted) return;
    _renderCenterMarkers();
  }

  /// Maps a center's `background` token to the solid color drawn behind its
  /// logo. Returns null when no background is configured.
  Color? _centerBackgroundColor(String? token) {
    switch (token?.trim()) {
      case 'darkGreen':
        // Matches the SOMOS location info card header color.
        return _markerColor;
      case 'white':
        return Colors.white;
      default:
        return null;
    }
  }

  /// Renders a small solid-color image that a [PictureMarkerSymbol] can stretch
  /// into a background behind a center's logo.
  Future<ArcGISImage?> _solidColorImage(Color color) async {
    const dimension = 16.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, dimension, dimension),
      Paint()..color = color,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(dimension.toInt(), dimension.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    if (data == null) return null;
    return ArcGISImage.withBuffer(data.buffer.asUint8List());
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
    _renderCenterMarkers();
    _renderFoodMarkers();
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

  /// Draws the campus centers with the shared placeholder pin. They live in
  /// their own overlay so they stay separate from the numbered resource icons.
  void _renderCenterMarkers() {
    _centersOverlay.graphics.clear();

    for (final center in _visibleCenters) {
      final point = ArcGISPoint(
        x: center.longitude,
        y: center.latitude,
        spatialReference: SpatialReference.wgs84,
      );

      _centersOverlay.graphics.add(
        Graphic(
          geometry: point,
          attributes: center.toAttributes(),
          symbol: _centerMarkerSymbol(
            iconAsset: center.iconAsset,
            background: center.background,
            iconScale: center.iconScale,
            backgroundPadding: center.backgroundPadding,
          ),
        ),
      );
    }
  }

  /// Draws the Latine food options with their food icons. They live in their own
  /// overlay so they stay separate from the numbered resource icons and the
  /// campus center logos.
  void _renderFoodMarkers() {
    _foodOverlay.graphics.clear();

    for (final food in _visibleFood) {
      final point = ArcGISPoint(
        x: food.longitude,
        y: food.latitude,
        spatialReference: SpatialReference.wgs84,
      );

      _foodOverlay.graphics.add(
        Graphic(
          geometry: point,
          attributes: food.toAttributes(),
          symbol: _foodMarkerSymbol(food.iconAsset),
        ),
      );
    }
  }

  /// The marker drawn for a Latine food option. Uses the bundled food icon when
  /// it has loaded, or a circle until then.
  ArcGISSymbol _foodMarkerSymbol(
    String iconAsset, {
    double size = _foodIconSize,
  }) {
    final image = _foodIconImages[iconAsset];
    if (image == null) {
      return SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: _markerColor,
        size: size,
      )..outline = SimpleLineSymbol(color: Colors.white, width: 2);
    }
    return _pictureMarkerSymbol(image, size);
  }

  /// The marker drawn for a campus center. Uses the center's own icon when it
  /// has loaded, then the shared placeholder icon, or a circle until then. When
  /// the center has a background token, a solid rectangle is drawn behind the
  /// logo (with padding) so low-contrast logos stay visible.
  ArcGISSymbol _centerMarkerSymbol({
    String? iconAsset,
    String? background,
    double size = _centerIconSize,
    double iconScale = 1.0,
    double backgroundPadding = 0.12,
  }) {
    final image =
        _centerIconImages[iconAsset] ??
        _centerIconImages[SomosCampusCenter.placeholderIconAsset];
    if (image == null) {
      return SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: _markerColor,
        size: size,
      )..outline = SimpleLineSymbol(color: Colors.white, width: 2);
    }

    final logoSize = size * iconScale;
    final logo = _pictureMarkerSymbol(image, logoSize);
    final backgroundImage = _centerBackgroundImages[background?.trim()];
    if (backgroundImage == null) return logo;

    final box = _fittedDimensions(image, logoSize);
    final padding = size * backgroundPadding;
    final backgroundMarker = PictureMarkerSymbol.withImage(backgroundImage)
      ..width = box.width + padding * 2
      ..height = box.height + padding * 2;

    // Background first so it is drawn underneath the logo.
    return CompositeSymbol(symbols: [backgroundMarker, logo]);
  }

  /// The box the image is drawn at inside a [size] square, preserving its
  /// original aspect ratio so wider or taller logos are not squished.
  Size _fittedDimensions(ArcGISImage image, double size) {
    final pixelWidth = image.width;
    final pixelHeight = image.height;
    if (pixelWidth <= 0 || pixelHeight <= 0) {
      return Size(size, size);
    }
    if (pixelWidth >= pixelHeight) {
      return Size(size, size * pixelHeight / pixelWidth);
    }
    return Size(size * pixelWidth / pixelHeight, size);
  }

  PictureMarkerSymbol _pictureMarkerSymbol(ArcGISImage image, double size) {
    final box = _fittedDimensions(image, size);
    return PictureMarkerSymbol.withImage(image)
      ..width = box.width
      ..height = box.height;
  }

  CompositeSymbol _markerSymbol(int number, {double size = 30}) {
    final cacheKey = '$number@$size';
    final cached = _markerSymbolCache[cacheKey];
    if (cached != null) return cached;

    final circle = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle,
      color: _markerColor,
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

      // The campus centers sit just below the numbered markers and above the
      // Latine art locations.
      final centerResult = await _mapController.identifyGraphicsOverlay(
        _centersOverlay,
        screenPoint: screenPoint,
        tolerance: 22.0,
        maximumResults: 1,
      );

      if (!mounted) return;

      final centerGraphic = centerResult.graphics.firstOrNull;
      final centerAttributes = centerGraphic?.attributes;
      if (centerGraphic != null &&
          centerAttributes != null &&
          centerAttributes.isNotEmpty) {
        _selectCenter(centerGraphic, centerAttributes);
        return;
      }

      // The Latine food icons sit below the numbered markers and the campus
      // centers, and above the art locations.
      final foodResult = await _mapController.identifyGraphicsOverlay(
        _foodOverlay,
        screenPoint: screenPoint,
        tolerance: 22.0,
        maximumResults: 1,
      );

      if (!mounted) return;

      final foodGraphic = foodResult.graphics.firstOrNull;
      final foodAttributes = foodGraphic?.attributes;
      if (foodGraphic != null &&
          foodAttributes != null &&
          foodAttributes.isNotEmpty) {
        _selectFood(foodGraphic, foodAttributes);
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

  /// Shows the info card for a tapped campus center and enlarges its marker.
  void _selectCenter(Graphic graphic, Map<String, dynamic> attributes) {
    setState(() {
      _selectedAttributes = attributes;
      _selectedLat = _toDouble(attributes['LATITUDE']);
      _selectedLng = _toDouble(attributes['LONGITUDE']);
      _showFullInfo = false;
      _selectedIsLatineArt = false;
      _showInfoCard = true;
    });

    _selectionOverlay.graphics.clear();
    _selectionOverlay.graphics.add(
      Graphic(
        geometry: graphic.geometry,
        attributes: attributes,
        symbol: _centerMarkerSymbol(
          iconAsset: attributes['ICON_ASSET']?.toString(),
          background: attributes['BACKGROUND']?.toString(),
          iconScale: _toDouble(attributes['ICON_SCALE']) ?? 1.0,
          backgroundPadding:
              _toDouble(attributes['BACKGROUND_PADDING']) ?? 0.12,
          size: _selectedCenterIconSize,
        ),
      ),
    );
  }

  /// Shows the info card for a tapped Latine food option and enlarges its icon.
  void _selectFood(Graphic graphic, Map<String, dynamic> attributes) {
    setState(() {
      _selectedAttributes = attributes;
      _selectedLat = _toDouble(attributes['LATITUDE']);
      _selectedLng = _toDouble(attributes['LONGITUDE']);
      _showFullInfo = false;
      _selectedIsLatineArt = false;
      _showInfoCard = true;
    });

    _selectionOverlay.graphics.clear();
    _selectionOverlay.graphics.add(
      Graphic(
        geometry: graphic.geometry,
        attributes: attributes,
        symbol: _foodMarkerSymbol(
          attributes['ICON_ASSET']?.toString() ??
              SomosCampusFood.defaultIconAsset,
          size: _selectedFoodIconSize,
        ),
      ),
    );
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
        color: _markerColor,
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
    return showCurrentLocation(
      _mapController,
      _userOverlay,
      context: context,
    );
  }

  Future<void> _browseLocations() async {
    if (_resources.isEmpty &&
        _centers.isEmpty &&
        _food.isEmpty &&
        _latineArtLocations.isEmpty) {
      return;
    }

    final visibleResources = _visibleResources;
    final visibleCenters = _visibleCenters;
    final visibleFood = _visibleFood;
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
      if (visibleCenters.isNotEmpty)
        MapLocationSource(
          name: 'Campus Centers',
          loadPage: (offset) async {
            final locations = visibleCenters
                .skip(offset)
                .take(mapLocationPageSize)
                .map(
                  (center) => MapLocation.fromAttributes(
                    center.toAttributes(),
                    category: center.category,
                  ),
                )
                .toList(growable: false);
            return MapLocationPage(
              locations,
              hasMore: offset + locations.length < visibleCenters.length,
            );
          },
        ),
      if (visibleFood.isNotEmpty)
        MapLocationSource(
          name: latineFoodCategory,
          loadPage: (offset) async {
            final locations = visibleFood
                .skip(offset)
                .take(mapLocationPageSize)
                .map(
                  (food) => MapLocation.fromAttributes(
                    food.toAttributes(),
                    category: food.category,
                  ),
                )
                .toList(growable: false);
            return MapLocationPage(
              locations,
              hasMore: offset + locations.length < visibleFood.length,
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

    final foodId = location.attributes['ID']?.toString();
    if (foodId != null) {
      for (final food in _food) {
        if (food.id == foodId) {
          await _showFoodOnMap(food);
          return;
        }
      }
    }

    final centerId = location.attributes['ID']?.toString();
    if (centerId != null) {
      for (final center in _centers) {
        if (center.id == centerId) {
          await _showCenterOnMap(center);
          return;
        }
      }
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

  Future<void> _showCenterOnMap(SomosCampusCenter center) async {
    final attributes = center.toAttributes();
    final point = ArcGISPoint(
      x: center.longitude,
      y: center.latitude,
      spatialReference: SpatialReference.wgs84,
    );

    setState(() {
      _selectedAttributes = attributes;
      _selectedLat = center.latitude;
      _selectedLng = center.longitude;
      _showFullInfo = false;
      _selectedIsLatineArt = false;
      _showInfoCard = true;
    });

    _selectionOverlay.graphics.clear();
    _selectionOverlay.graphics.add(
      Graphic(
        geometry: point,
        attributes: attributes,
        symbol: _centerMarkerSymbol(
          iconAsset: center.iconAsset,
          background: center.background,
          iconScale: center.iconScale,
          backgroundPadding: center.backgroundPadding,
          size: _selectedCenterIconSize,
        ),
      ),
    );

    await _mapController.setViewpointCenter(point, scale: 5000);
  }

  Future<void> _showFoodOnMap(SomosCampusFood food) async {
    final attributes = food.toAttributes();
    final point = ArcGISPoint(
      x: food.longitude,
      y: food.latitude,
      spatialReference: SpatialReference.wgs84,
    );

    setState(() {
      _selectedAttributes = attributes;
      _selectedLat = food.latitude;
      _selectedLng = food.longitude;
      _showFullInfo = false;
      _selectedIsLatineArt = false;
      _showInfoCard = true;
    });

    _selectionOverlay.graphics.clear();
    _selectionOverlay.graphics.add(
      Graphic(
        geometry: point,
        attributes: attributes,
        symbol: _foodMarkerSymbol(food.iconAsset, size: _selectedFoodIconSize),
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

  Future<void> _selectCenterSuggestion(SomosCampusCenter center) async {
    _searchController.text = center.name;
    setState(() {
      _searchQuery = center.name;
      _showSearchSuggestions = false;
    });
    _renderResourceMarkers();
    await _showCenterOnMap(center);
  }

  Future<void> _selectFoodSuggestion(SomosCampusFood food) async {
    _searchController.text = food.name;
    setState(() {
      _searchQuery = food.name;
      _showSearchSuggestions = false;
    });
    _renderResourceMarkers();
    await _showFoodOnMap(food);
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
            if (_resources.isNotEmpty ||
                _centers.isNotEmpty ||
                _food.isNotEmpty) ...[
              const SizedBox(width: 12),
              MapFilterButton(
                key: ValueKey<int>(
                  _resources.length + _centers.length + _food.length,
                ),
                featureLayer: null,
                filterField: 'CATEGORY',
                label: 'Category',
                loadFilters: () async {
                  final categories = <String>{
                    ...somosCampusResourceCategories(_resources),
                    ...somosCampusCenterCategories(_centers),
                    ...somosCampusFoodCategories(_food),
                    latineArtCategory,
                  };
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
                  if ((_resources.isNotEmpty ||
                          _centers.isNotEmpty ||
                          _food.isNotEmpty) &&
                      _selectedAttributes == null)
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