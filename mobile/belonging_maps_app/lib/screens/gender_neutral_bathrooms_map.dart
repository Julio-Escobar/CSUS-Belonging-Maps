import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '/constants/campus_map_urls.dart';
import '/models/location_attributes.dart';
import '/services/accessibility_theme.dart';
import '/services/campus_map_bounds.dart';
import '/services/current_location.dart';
import '/services/map_location_source.dart';
import '/services/map_tap_target.dart';
import '/widgets/current_location_buttons.dart';
import '/widgets/gender_neutral_bathroom_info_card.dart';
import '/widgets/map_location_browser.dart';
import '/widgets/map_zoom_controls.dart';

/// Point locations of gender neutral bathrooms across the Sacramento State
/// campus, from the MLRC Campus_MLRC Story Map.
const String genderNeutralBathroomsLayerUrl =
    'https://services5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/services/Gender_Neutral_Bathrooms/FeatureServer/0';

/// Building footprints used to highlight buildings that contain gender
/// neutral bathrooms. The layer is filtered to GenderNeutralBathrooms = 1.
const String genderNeutralBathroomsBuildingsLayerUrl =
    'https://services5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/services/BuildingsV2/FeatureServer/0';

/// Bundled gender neutral restroom pictogram used for the point markers.
const String genderNeutralBathroomIconAsset =
    'assets/map_icons/general/GenderNeutralBathroom.png';

const double _restroomIconSize = 28;
const double _selectedRestroomIconScale = 1.6;
const double _selectedRestroomIconSize =
    _restroomIconSize * _selectedRestroomIconScale;
const double _campusScale = 10000;

/// Title shown for a restroom in the browse locations list.
///
/// The restroom layer has no name field, so the building name doubles as the
/// location name the way [locationTitleFromAttributes] does on other maps.
String genderNeutralBathroomListingName(Map<String, dynamic> attributes) {
  final buildingName = cleanLocationAttribute(attributes['BuildingName']);
  return buildingName.isEmpty ? 'Gender Neutral Bathroom' : buildingName;
}

/// Subtitle shown under [genderNeutralBathroomListingName] in the browse list.
///
/// Restrooms in the same building are only distinguished by floor and location
/// details, so both are shown when the layer records them.
String genderNeutralBathroomListingCategory(Map<String, dynamic> attributes) {
  final floor = cleanLocationAttribute(attributes['Floor']);
  final details = cleanLocationAttribute(attributes['LocationDetails']);
  final parts = [
    if (floor.isNotEmpty) 'Floor $floor',
    if (details.isNotEmpty) details,
  ];
  return parts.isEmpty ? 'Gender neutral bathroom' : parts.join(' • ');
}

class GenderNeutralBathroomsMap extends StatefulWidget {
  const GenderNeutralBathroomsMap({super.key});

  @override
  State<GenderNeutralBathroomsMap> createState() =>
      _GenderNeutralBathroomsMapState();
}

class _GenderNeutralBathroomsMapState extends State<GenderNeutralBathroomsMap> {
  late final ArcGISMap _map;
  late final ArcGISMapViewController _mapController;
  late final FeatureLayer _buildingsLayer;
  late final FeatureLayer _restroomLayer;

  Map<String, dynamic>? _selectedAttributes;
  final GraphicsOverlay _userOverlay = GraphicsOverlay();
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();
  ArcGISImage? _restroomIconImage;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();

    final campusBasemapLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(campusBasemapUrl),
    );
    final campusLabelsLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(campusLabelsStyleUrl),
    );

    // The OpenStreetMap streets basemap style supplies the surrounding city
    // context; the campus vector tiles draw above it.
    _map = ArcGISMap.withBasemapStyle(BasemapStyle.openStreets)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: campusMapLatitude,
        longitude: campusMapLongitude,
        scale: _campusScale,
      )
      ..maxExtent = campusMapMaxExtent();

    _buildingsLayer =
        FeatureLayer.withFeatureTable(
            ServiceFeatureTable.withUri(
              Uri.parse(genderNeutralBathroomsBuildingsLayerUrl),
            ),
          )
          ..definitionExpression = 'GenderNeutralBathrooms = 1'
          ..renderer = SimpleRenderer(
            symbol: SimpleFillSymbol(
              color: const Color.fromARGB(255, 216, 155, 242),
              outline: SimpleLineSymbol(
                color: const Color.fromARGB(255, 117, 81, 156),
                width: 1.8,
              ),
            ),
          );

    // Start with a visible fallback marker while the restroom icon loads.
    _restroomLayer =
        FeatureLayer.withFeatureTable(
            ServiceFeatureTable.withUri(
              Uri.parse(genderNeutralBathroomsLayerUrl),
            ),
          )
          ..renderer = SimpleRenderer(
            symbol: SimpleMarkerSymbol(
              style: SimpleMarkerSymbolStyle.circle,
              color: const Color.fromARGB(255, 117, 81, 156),
              size: _restroomIconSize,
            )..outline = SimpleLineSymbol(color: Colors.white, width: 2),
          );

    // The campus tiles draw above the basemap, then the highlighted building
    // footprints and their labels, with the restroom markers on top.
    _map.operationalLayers.add(campusBasemapLayer);
    _map.operationalLayers.add(_buildingsLayer);
    _map.operationalLayers.add(campusLabelsLayer);
    _map.operationalLayers.add(_restroomLayer);

    _mapController = ArcGISMapView.createController()..arcGISMap = _map;
    _mapController.graphicsOverlays.addAll([_userOverlay, _selectionOverlay]);
    _applyRestroomIcon();
    _loadMapData();
  }

  Future<void> _applyRestroomIcon() async {
    try {
      final image = await ArcGISImage.fromAsset(genderNeutralBathroomIconAsset);

      if (!mounted) return;
      _restroomIconImage = image;
      _restroomLayer.renderer = SimpleRenderer(
        symbol: _restroomMarkerSymbol(image, _restroomIconSize),
      );
    } catch (error) {
      // Keep the fallback circle marker if the icon cannot be loaded.
      debugPrint('Failed to load the gender neutral restroom icon: $error');
    }
  }

  PictureMarkerSymbol _restroomMarkerSymbol(ArcGISImage image, double size) {
    return PictureMarkerSymbol.withImage(image)
      ..width = size
      ..height = size;
  }

  /// Draws an enlarged copy of the restroom icon above the selected point.
  void _showSelectedRestroomIcon(Geometry? geometry) {
    _selectionOverlay.graphics.clear();
    if (geometry is! ArcGISPoint) return;

    final image = _restroomIconImage;
    final ArcGISSymbol symbol;
    if (image != null) {
      symbol = _restroomMarkerSymbol(image, _selectedRestroomIconSize);
    } else {
      symbol = SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: const Color.fromARGB(255, 117, 81, 156),
        size: _selectedRestroomIconSize,
      )..outline = SimpleLineSymbol(color: Colors.white, width: 2);
    }

    _selectionOverlay.graphics.add(Graphic(geometry: geometry, symbol: symbol));
  }

  /// Selects a restroom chosen from the browse locations sheet: shows its
  /// details card and zooms the map in on the marker.
  void _selectRestroom(MapLocation location) {
    setState(() => _selectedAttributes = location.attributes);
    _showSelectedRestroomIcon(location.geometry);
    final geometry = location.geometry;
    if (geometry is ArcGISPoint) {
      _mapController.setViewpointCenter(geometry, scale: 5000);
    }
  }

  /// Opens the browse locations sheet for the restroom layer.
  Future<void> _browseBathrooms() async {
    final featureSource = arcGisLocationSource(
      name: 'Gender Neutral Bathrooms',
      layer: _restroomLayer,
    );
    final source = MapLocationSource(
      name: 'Gender Neutral Bathrooms',
      loadPage: (offset) async {
        final page = await featureSource.loadPage(offset);
        return MapLocationPage(
          page.locations
              .map(
                (location) => MapLocation(
                  name: genderNeutralBathroomListingName(location.attributes),
                  category: genderNeutralBathroomListingCategory(
                    location.attributes,
                  ),
                  attributes: location.attributes,
                  geometry: location.geometry,
                ),
              )
              .toList(growable: false),
          hasMore: page.hasMore,
        );
      },
    );
    final location = await showMapLocationBrowser(context, [source]);
    if (mounted && location != null) _selectRestroom(location);
  }

  /// Loads the map and both feature layers. A failure puts the screen into an
  /// error state where the user can retry or return to the directory.
  Future<void> _loadMapData({bool retry = false}) async {
    if (!_isLoading || _loadFailed) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }

    try {
      await Future.wait([
        retry ? _map.retryLoad() : _map.load(),
        retry ? _buildingsLayer.retryLoad() : _buildingsLayer.load(),
        retry ? _restroomLayer.retryLoad() : _restroomLayer.load(),
      ], eagerError: true);

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    if (_isLoading || _loadFailed) return;

    final result = await _mapController.identifyLayer(
      _restroomLayer,
      screenPoint: screenPoint,
      tolerance: mapIconTapTolerance(_selectedRestroomIconSize),
      maximumResults: 5,
    );

    if (!mounted) return;

    final candidates = <MapTapCandidate<VoidCallback>>[];
    for (final element in result.geoElements) {
      final attributes = element.attributes;
      if (attributes.isEmpty) continue;

      final position = mapGeometryScreenPoint(_mapController, element.geometry);
      if (position == null) continue;

      candidates.add(
        MapTapCandidate(
          value: () {
            setState(() => _selectedAttributes = attributes);
            _showSelectedRestroomIcon(element.geometry);
          },
          screenPoint: position,
          tolerance: mapIconTapTolerance(_selectedRestroomIconSize),
        ),
      );
    }

    final onSelected = nearestMapTapCandidate(candidates, screenPoint);
    if (onSelected == null) {
      _dismissLocationCard();
      return;
    }

    onSelected();
  }

  void _dismissLocationCard() {
    if (_selectedAttributes == null) return;
    _selectionOverlay.graphics.clear();
    setState(() => _selectedAttributes = null);
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

  String get _selectedBuildingName =>
      cleanLocationAttribute(_selectedAttributes?['BuildingName']);

  String get _selectedFloor =>
      cleanLocationAttribute(_selectedAttributes?['Floor']);

  String get _selectedDescription =>
      cleanLocationAttribute(_selectedAttributes?['LocationDetails']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.maybePop(context)),
        title: const Text(
          'Gender Neutral Bathrooms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loadFailed
          ? _buildErrorState(context)
          : Stack(
              children: [
                ArcGISMapView(
                  controllerProvider: () => _mapController,
                  onTap: _handleMapTap,
                ),
                MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
                CurrentLocationButton(onPressed: _getCurrentLocation),
                Positioned(
                  top: 12,
                  right: 12,
                  child: SafeArea(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _browseBathrooms,
                      icon: const Icon(Icons.list),
                      label: const Text('Browse bathrooms'),
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
                  GenderNeutralBathroomInfoCard(
                    buildingName: _selectedBuildingName,
                    floor: _selectedFloor,
                    description: _selectedDescription,
                    onClose: _dismissLocationCard,
                  ),
              ],
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
              "The gender neutral bathrooms map couldn't be loaded. "
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
