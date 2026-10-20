import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

import '/models/somos_campus_resource.dart';
import '/services/accessibility_theme.dart';
import '/services/current_location.dart';
import '/services/somos_campus_resources.dart';
import '/widgets/current_location_buttons.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import '/widgets/map_filter_button.dart';
import '/widgets/map_search_bar.dart';
import '/widgets/somos_campus_resource_list.dart';

const String somosCampusBasemapUrl =
    'https://vectortileservices5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/services/CampusBasemapv3/VectorTileServer';
const String _openStreetMapBasemapUrl =
    'https://basemaps.arcgis.com/arcgis/rest/services/OpenStreetMap_v2/VectorTileServer';
const Color _somosMarkerColor = Color(0xFF2F5F3E);
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
  final TextEditingController _searchController = TextEditingController();
  final GraphicsOverlay _userOverlay = GraphicsOverlay();
  final GraphicsOverlay _resourcesOverlay = GraphicsOverlay();
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();
  final Map<String, CompositeSymbol> _markerSymbolCache = {};

  List<SomosCampusResource> _resources = const [];
  Map<String, dynamic>? _selectedAttributes;
  double? _selectedLat;
  double? _selectedLng;
  bool _showFullInfo = false;
  bool _showInfoCard = false;
  bool _isLoading = true;
  bool _loadFailed = false;
  String _searchQuery = '';
  Set<String> _selectedCategories = const <String>{};

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

    _mapController = ArcGISMapView.createController()..arcGISMap = _map;
    _mapController.graphicsOverlays.addAll([
      _userOverlay,
      _resourcesOverlay,
      _selectionOverlay,
    ]);
    _loadMapData();
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
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  void _onSearchChanged(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery == _searchQuery) return;

    _searchQuery = normalizedQuery;
    _refreshResourceMarkers();
  }

  void _onCategoryFilterChanged(String expression) {
    final categories = parseCategoryFilterExpression(expression);
    if (categories.length == _selectedCategories.length &&
        categories.containsAll(_selectedCategories)) {
      return;
    }

    _selectedCategories = categories;
    _refreshResourceMarkers();
  }

  void _refreshResourceMarkers() {
    if (_selectedAttributes != null) {
      _dismissLocationCard();
    }
    _renderResourceMarkers();
  }

  void _renderResourceMarkers() {
    _resourcesOverlay.graphics.clear();
    _selectionOverlay.graphics.clear();

    final visibleResources = filterSomosCampusResources(
      _resources,
      query: _searchQuery,
      categories: _selectedCategories,
    );

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

      final graphic = result.graphics.firstOrNull;
      final attributes = graphic?.attributes;
      if (graphic == null || attributes == null || attributes.isEmpty) {
        _dismissLocationCard();
        return;
      }

      final number = attributes['NUMBER'];
      setState(() {
        _selectedAttributes = attributes;
        _selectedLat = _toDouble(attributes['LATITUDE']);
        _selectedLng = _toDouble(attributes['LONGITUDE']);
        _showFullInfo = false;
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
    } catch (error) {
      debugPrint('Failed to identify a SOMOS campus resource: $error');
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _getCurrentLocation() {
    return showCurrentLocation(_mapController, _userOverlay);
  }

  Future<void> _showResourceList() async {
    if (_resources.isEmpty) return;

    final resource = await showSomosCampusResourceList(context, _resources);
    if (!mounted || resource == null) return;

    await _showResourceOnMap(resource);
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

    return LocationInfoData(
      cardTitle: resourceName.isNotEmpty
          ? resourceName
          : 'SOMOS Campus Resource',
      address: _cleanField(attributes?['ADDRESS']),
      category: _cleanField(attributes?['CATEGORY']),
      type: '',
      website: _cleanField(attributes?['WEBSITE']),
      phone: _cleanField(attributes?['PHONE']),
      email: _cleanField(attributes?['EMAIL']),
      description: _cleanField(attributes?['DESCRIPTION']),
      imageUrl: null,
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
      showFullInfo: _showFullInfo,
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
                  ).toList();
                  categories.sort();
                  return categories;
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
                          onPressed: _showResourceList,
                          icon: const Icon(Icons.list),
                          label: const Text('List'),
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
