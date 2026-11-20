import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

import '/models/ubuntu_campus_center.dart';
import '/models/ubuntu_campus_resource.dart';
import '/services/accessibility_theme.dart';
import '/services/campus_map_bounds.dart';
import '/services/campus_map_card_logo.dart';
import '/services/current_location.dart';
import '/services/map_camera.dart';
import '/services/map_location_source.dart';
import '/services/map_tap_target.dart';
import '/services/ubuntu_campus_centers.dart';
import '/services/ubuntu_campus_resources.dart';
import '/widgets/current_location_buttons.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import '/widgets/map_filter_button.dart';
import '/widgets/map_location_browser.dart';
import '/widgets/map_search_bar.dart';
import '/widgets/search_suggestion_list.dart';

/// The Sacramento State campus vector basemap shared with the other Belonging
/// maps. It draws the campus building footprints over a global OpenStreetMap
/// basemap.
const String ubuntuCampusBasemapUrl =
    'https://vectortileservices5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/services/CampusBasemapv3/VectorTileServer';
const String _openStreetMapBasemapUrl =
    'https://basemaps.arcgis.com/arcgis/rest/services/OpenStreetMap_v2/VectorTileServer';

/// Label-only "Light Gray Reference" vector tile style that supplies the
/// building names. The CampusBasemapv3 style has no label layers of its own,
/// so this draws the labels above the campus tiles and below the markers.
const String ubuntuCampusLabelsStyleUrl =
    'https://www.arcgis.com/sharing/rest/content/items/a8416e7b45034be7b748071e10dde506/resources/styles/root.json';

const Color _ubuntuMarkerColor = Color(0xFF2F5F3E);

/// The Ubuntu community logo, shown in a location card only when the location
/// has no marker icon or number of its own.
const String _defaultOrgLogoAsset = 'assets/ubuntu_logo_temp.png';

// The campus center logos are drawn larger than the numbered markers so their
// wordmarks stay legible, and enlarged further when selected.
const double _centerIconSize = 40;
const double _selectedCenterIconSize = 56;

const double _campusScale = 8000;

/// The category filter options for the Ubuntu campus map: the same sections the
/// Browse locations list shows for the loaded datasets.
Set<String> ubuntuCampusFilterCategories({
  required List<UbuntuCampusResource> resources,
  required List<UbuntuCampusCenter> centers,
}) {
  return <String>{
    if (centers.isNotEmpty) ubuntuCampusCentersCategory,
    if (resources.isNotEmpty) ubuntuCampusResourcesCategory,
  };
}

class UbuntuCampusMap extends StatefulWidget {
  const UbuntuCampusMap({super.key});

  @override
  State<UbuntuCampusMap> createState() => _UbuntuCampusMapState();
}

class _UbuntuCampusMapState extends State<UbuntuCampusMap> {
  late final ArcGISMap _map;
  late final ArcGISMapViewController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final GraphicsOverlay _userOverlay = GraphicsOverlay();
  final GraphicsOverlay _centersOverlay = GraphicsOverlay();
  final GraphicsOverlay _resourcesOverlay = GraphicsOverlay();
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();
  final Map<String, CompositeSymbol> _markerSymbolCache = {};

  List<UbuntuCampusResource> _resources = const [];
  List<UbuntuCampusCenter> _centers = const [];
  final Map<String, ArcGISImage> _centerIconImages = {};
  final Map<String, ArcGISImage> _centerBackgroundImages = {};
  Map<String, dynamic>? _selectedAttributes;
  double? _selectedLat;
  double? _selectedLng;
  bool _showFullInfo = false;
  bool _showInfoCard = false;
  bool _isLoading = true;
  bool _loadFailed = false;
  String _searchQuery = '';
  Set<String> _selectedCategories = const <String>{};
  bool _showSearchSuggestions = true;

  List<UbuntuCampusResource> get _visibleResources =>
      filterUbuntuCampusResources(
        _resources,
        query: _searchQuery,
        categories: _selectedCategories,
        browseCategory: ubuntuCampusResourcesCategory,
      );

  List<UbuntuCampusCenter> get _visibleCenters => filterUbuntuCampusCenters(
    _centers,
    query: _searchQuery,
    categories: _selectedCategories,
    browseCategory: ubuntuCampusCentersCategory,
  );

  /// Suggestions for the current query: the numbered campus resources first,
  /// then the featured Black-serving centers that match.
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
                _selectResourceSuggestion(resource);
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
    ].take(5).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();

    final openStreetMapLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(_openStreetMapBasemapUrl),
    );
    final campusBasemapLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(ubuntuCampusBasemapUrl),
    );
    final campusLabelsLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(ubuntuCampusLabelsStyleUrl),
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
            latitude: campusMapLatitude,
            longitude: campusMapLongitude,
            scale: _campusScale,
          )
          ..maxExtent = campusMapMaxExtent();

    // The label tiles draw above the campus tiles but below the markers so the
    // building names stay readable and the markers stay on top.
    _map.operationalLayers.add(campusLabelsLayer);

    _mapController = ArcGISMapView.createController()..arcGISMap = _map;
    // Overlays draw bottom-to-top: later entries render above earlier ones.
    // The centers are added last (below only the enlarged selection icon) so
    // they are the top layer of location icons. Tapping relies on the SDK's
    // top-to-bottom identify results to break ties in the centers' favour.
    _mapController.graphicsOverlays.addAll([
      _userOverlay,
      _resourcesOverlay,
      _centersOverlay,
      _selectionOverlay,
    ]);

    _loadMapData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads the bundled datasets and the map, then draws the markers. Failures
  /// surface the map's error state so the user can retry.
  Future<void> _loadMapData({bool retry = false}) async {
    try {
      final resources = await loadUbuntuCampusResources();

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
      await _loadCampusCenters();
    } catch (error) {
      debugPrint('Failed to load the Ubuntu campus resources: $error');
      if (!mounted) return;

      _centersOverlay.graphics.clear();
      _resourcesOverlay.graphics.clear();
      _selectionOverlay.graphics.clear();
      setState(() {
        _resources = const [];
        _centers = const [];
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  /// Loads the featured Black-serving centers from the bundled dataset and
  /// draws their markers. A failure is logged instead of failing the whole
  /// screen, because the numbered resources still work without them.
  Future<void> _loadCampusCenters() async {
    try {
      final centers = await loadUbuntuCampusCenters();
      if (!mounted) return;

      setState(() {
        _centers = centers;
      });
      _renderCenterMarkers();
      unawaited(_loadCenterIcons());
    } catch (error) {
      debugPrint('Failed to load the Ubuntu campus centers: $error');
    }
  }

  /// Loads the bundled icon for each distinct center marker and redraws them.
  /// Missing icons are skipped so the other markers still render.
  Future<void> _loadCenterIcons() async {
    final assets = <String>{
      UbuntuCampusCenter.placeholderIconAsset,
      for (final center in _centers) center.iconAsset,
    };

    for (final asset in assets) {
      try {
        final image = await ArcGISImage.fromAsset(asset);
        if (!mounted) return;
        _centerIconImages[asset] = image;
      } catch (error) {
        debugPrint(
          'Failed to load the Ubuntu campus center icon $asset: $error',
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
        // Matches the Somos location info card header color.
        return mapInfoCardColor;
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

  void _refreshResourceMarkers() {
    if (_selectedAttributes != null) {
      _dismissLocationCard();
    }
    _renderResourceMarkers();
    _renderCenterMarkers();
  }

  void _renderResourceMarkers() {
    _resourcesOverlay.graphics.clear();
    _selectionOverlay.graphics.clear();

    for (final resource in _visibleResources) {
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

  /// Draws the featured centers with the shared placeholder pin. They live in
  /// their own overlay so they stay separate from the numbered resource icons,
  /// and it is added after the other marker overlays so the centers are the top
  /// layer of location icons.
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
        _centerIconImages[UbuntuCampusCenter.placeholderIconAsset];
    if (image == null) {
      return SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: _ubuntuMarkerColor,
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
      color: _ubuntuMarkerColor,
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
      final overlays = [_centersOverlay, _resourcesOverlay, _selectionOverlay];

      // A single generous search radius finds every icon near the tap; each
      // result is then limited by the size of its own drawn symbol below.
      final overlayResults = await _mapController.identifyGraphicsOverlays(
        screenPoint: screenPoint,
        tolerance: mapOverlaysTapSearchTolerance(overlays),
        // No cap: the nearest icon must win even in a dense cluster.
        maximumResultsPerOverlay: null,
      );

      if (!mounted) return;

      // Results are returned top-most first, which is also the order used to
      // break ties between icons that share a location.
      final candidates = <MapTapCandidate<VoidCallback>>[];

      for (final result in overlayResults) {
        final overlay = result.graphicsOverlay;
        if (!overlays.contains(overlay)) continue;
        final isSelection = identical(overlay, _selectionOverlay);

        for (final graphic in result.graphics) {
          final attributes = graphic.attributes;
          if (!isSelection && attributes.isEmpty) continue;

          final position = mapGeometryScreenPoint(
            _mapController,
            graphic.geometry,
          );
          if (position == null) continue;

          final VoidCallback? onSelected;
          if (isSelection) {
            // The card for the enlarged icon is already open; tapping it still
            // recenters the camera on the location.
            onSelected = () =>
                centerMapOnLocation(_mapController, graphic.geometry);
          } else if (identical(overlay, _resourcesOverlay)) {
            onSelected = () => _selectResource(graphic, attributes);
          } else if (identical(overlay, _centersOverlay)) {
            onSelected = () => _selectCenter(graphic, attributes);
          } else {
            onSelected = null;
          }
          if (onSelected == null) continue;

          candidates.add(
            MapTapCandidate(
              value: onSelected,
              screenPoint: position,
              tolerance: mapSymbolTapTolerance(graphic.symbol),
            ),
          );
        }
      }

      final onSelected = nearestMapTapCandidate(candidates, screenPoint);
      if (onSelected == null) {
        _dismissLocationCard();
        return;
      }

      onSelected();
    } catch (error) {
      debugPrint('Failed to identify an Ubuntu campus resource: $error');
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

    centerMapOnLocation(_mapController, graphic.geometry);
  }

  /// Shows the info card for a tapped campus center and enlarges its marker.
  void _selectCenter(Graphic graphic, Map<String, dynamic> attributes) {
    setState(() {
      _selectedAttributes = attributes;
      _selectedLat = _toDouble(attributes['LATITUDE']);
      _selectedLng = _toDouble(attributes['LONGITUDE']);
      _showFullInfo = false;
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

    centerMapOnLocation(_mapController, graphic.geometry);
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void _onSearchChanged(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery == _searchQuery) return;

    setState(() {
      _searchQuery = normalizedQuery;
      _showSearchSuggestions = true;
    });
    _refreshResourceMarkers();
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

  Future<void> _getCurrentLocation() {
    return showCurrentLocation(context, _mapController, _userOverlay);
  }

  Future<void> _browseLocations() async {
    if (_resources.isEmpty && _centers.isEmpty) return;

    final visibleResources = _visibleResources;
    final visibleCenters = _visibleCenters;

    final location = await showMapLocationBrowser(context, [
      if (visibleResources.isNotEmpty)
        MapLocationSource(
          name: ubuntuCampusResourcesCategory,
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
      if (visibleCenters.isNotEmpty)
        MapLocationSource(
          name: ubuntuCampusCentersCategory,
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
    ]);
    if (!mounted || location == null) return;

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

  Future<void> _showResourceOnMap(UbuntuCampusResource resource) async {
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

  Future<void> _showCenterOnMap(UbuntuCampusCenter center) async {
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

  Future<void> _selectResourceSuggestion(UbuntuCampusResource resource) async {
    _searchController.text = resource.name;
    setState(() {
      _searchQuery = resource.name;
      _showSearchSuggestions = false;
    });
    _renderResourceMarkers();
    await _showResourceOnMap(resource);
  }

  Future<void> _selectCenterSuggestion(UbuntuCampusCenter center) async {
    _searchController.text = center.name;
    setState(() {
      _searchQuery = center.name;
      _showSearchSuggestions = false;
    });
    _renderResourceMarkers();
    await _showCenterOnMap(center);
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

    // Centers show the same icon as their map marker beside the card title;
    // every other location uses the icon drawn for its marker.
    final center = _selectedCenter();
    final icon = campusMapCardLogo(
      centerIconAsset: center?.iconAsset,
      mapLogoAsset: _defaultOrgLogoAsset,
      centerBackgroundColor: _centerBackgroundColor(center?.background),
      iconAsset: center == null ? _cleanField(attributes?['ICON_ASSET']) : null,
      resourceNumber: center == null
          ? _cleanField(attributes?['NUMBER'])
          : null,
      markerColor: _ubuntuMarkerColor,
    );

    return LocationInfoData.fromAttributes(
      attributes,
      fallbackTitle: 'Ubuntu Campus Resource',
      locationLat: _selectedLat,
      locationLng: _selectedLng,
      orgLogo: icon.asset,
      orgLogoLabel: icon.label,
      // Center logos are wide wordmarks, so they are fitted inside the card's
      // logo box instead of being cropped to a circle. The Ubuntu map logo is
      // square and keeps the original circular avatar.
      orgLogoFit: icon.fit,
      orgLogoBackgroundColor: icon.backgroundColor,
    );
  }

  /// The campus center the card is describing, or null when another kind of
  /// Ubuntu location (a numbered campus resource) is selected.
  UbuntuCampusCenter? _selectedCenter() {
    final id = _cleanField(_selectedAttributes?['ID']);
    if (id.isEmpty) return null;
    for (final center in _centers) {
      if (center.id == id) return center;
    }
    return null;
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (_resources.isNotEmpty || _centers.isNotEmpty) ...[
              const SizedBox(width: 12),
              MapFilterButton(
                key: ValueKey<int>(_resources.length + _centers.length),
                featureLayer: null,
                filterField: 'CATEGORY',
                label: 'Category',
                loadFilters: () async {
                  final categories = ubuntuCampusFilterCategories(
                    resources: _resources,
                    centers: _centers,
                  );
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
      title: 'Ubuntu Campus Map',
      showBackButton: true,
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
                  if ((_resources.isNotEmpty || _centers.isNotEmpty) &&
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
              "The Ubuntu campus resources couldn't be loaded. "
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
