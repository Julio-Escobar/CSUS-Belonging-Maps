import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '/models/location_attributes.dart';
import '/services/accessibility_theme.dart';
import '/services/campus_map_bounds.dart';
import '/services/current_location.dart';
import '/services/map_location_source.dart';
import '/services/map_tap_target.dart';
import '/widgets/current_location_buttons.dart';
import '/widgets/lactation_room_info_card.dart';
import '/widgets/map_location_browser.dart';
import '/widgets/map_zoom_controls.dart';

/// Official Sacramento State lactation room point layer.
const String lactationRoomsLayerUrl =
    'https://services5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/services/'
    'SacStateMothersRooms/FeatureServer/0';

/// Sacramento State campus vector basemap shared with the other Belonging
/// maps, drawn over the OpenStreetMap streets basemap style.
const String lactationCampusBasemapUrl =
    'https://vectortileservices5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/'
    'services/CampusBasemapv3/VectorTileServer';

/// Label-only "Light Gray Reference" vector tile style (ArcGIS item
/// a8416e7b45034be7b748071e10dde506, "LightGreyReferenceEdited") that supplies
/// the building names above the campus tiles.
const String lactationCampusLabelsStyleUrl =
    'https://www.arcgis.com/sharing/rest/content/items/'
    'a8416e7b45034be7b748071e10dde506/resources/styles/root.json';

const double _campusScale = 8500;

/// Size of the enlarged marker drawn for the selected lactation room.
const double _selectedRoomIconSize = 44;

class LactationRoomsMap extends StatefulWidget {
  const LactationRoomsMap({super.key});

  @override
  State<LactationRoomsMap> createState() => _LactationRoomsMapState();
}

class _LactationRoomsMapState extends State<LactationRoomsMap> {
  late final ArcGISMap _map;
  late final ArcGISMapViewController _mapController;
  late final FeatureLayer _roomsLayer;
  final GraphicsOverlay _userOverlay = GraphicsOverlay();
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();
  ArcGISImage? _roomIconImage;
  Map<String, dynamic>? _selectedAttributes;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();

    final campusBasemapLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(lactationCampusBasemapUrl),
    );
    final campusLabelsLayer = ArcGISVectorTiledLayer.withUri(
      Uri.parse(lactationCampusLabelsStyleUrl),
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

    _roomsLayer =
        FeatureLayer.withFeatureTable(
            ServiceFeatureTable.withUri(Uri.parse(lactationRoomsLayerUrl)),
          )
          ..renderer = SimpleRenderer(
            symbol: SimpleMarkerSymbol(
              style: SimpleMarkerSymbolStyle.circle,
              color: const Color.fromARGB(255, 47, 95, 62),
              size: 30,
            )..outline = SimpleLineSymbol(color: Colors.white, width: 2),
          );

    // The campus tiles draw above the basemap and the label tiles above them,
    // with the room markers on top so the building names stay readable.
    _map.operationalLayers
      ..add(campusBasemapLayer)
      ..add(campusLabelsLayer)
      ..add(_roomsLayer);
    _mapController = ArcGISMapView.createController()..arcGISMap = _map;
    _mapController.graphicsOverlays.addAll([_userOverlay, _selectionOverlay]);
    _applyRoomIcon();
    _loadMapData();
  }

  Future<void> _applyRoomIcon() async {
    try {
      final image = await ArcGISImage.fromAsset(lactationRoomsIconAsset);
      if (!mounted) return;

      _roomIconImage = image;
      _roomsLayer.renderer = SimpleRenderer(
        symbol: _roomMarkerSymbol(image, 30),
      );
    } catch (error) {
      debugPrint('Failed to load the lactation room icon: $error');
    }
  }

  PictureMarkerSymbol _roomMarkerSymbol(ArcGISImage image, double size) {
    return PictureMarkerSymbol.withImage(image)
      ..width = size
      ..height = size;
  }

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
        retry ? _roomsLayer.retryLoad() : _roomsLayer.load(),
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
      _roomsLayer,
      screenPoint: screenPoint,
      tolerance: mapIconTapTolerance(_selectedRoomIconSize),
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
            _showSelectedRoomIcon(element.geometry);
          },
          screenPoint: position,
          tolerance: mapIconTapTolerance(_selectedRoomIconSize),
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

  void _showSelectedRoomIcon(Geometry? geometry) {
    _selectionOverlay.graphics.clear();
    if (geometry is! ArcGISPoint) return;

    final image = _roomIconImage;
    final ArcGISSymbol symbol = image == null
        ? (SimpleMarkerSymbol(
            style: SimpleMarkerSymbolStyle.circle,
            color: const Color.fromARGB(255, 47, 95, 62),
            size: _selectedRoomIconSize,
          )..outline = SimpleLineSymbol(color: Colors.white, width: 2))
        : _roomMarkerSymbol(image, _selectedRoomIconSize);
    _selectionOverlay.graphics.add(Graphic(geometry: geometry, symbol: symbol));
  }

  void _selectRoom(MapLocation location) {
    setState(() => _selectedAttributes = location.attributes);
    _showSelectedRoomIcon(location.geometry);
    final geometry = location.geometry;
    if (geometry is ArcGISPoint) {
      _mapController.setViewpointCenter(geometry, scale: 5000);
    }
  }

  Future<void> _browseRooms() async {
    final featureSource = arcGisLocationSource(
      name: 'Lactation Rooms',
      layer: _roomsLayer,
    );
    final source = MapLocationSource(
      name: 'Lactation Rooms',
      loadPage: (offset) async {
        final page = await featureSource.loadPage(offset);
        return MapLocationPage(
          page.locations
              .map(
                (location) => MapLocation(
                  name: location.name,
                  category: cleanLocationAttribute(
                    location.attributes['MothersRoomInfo'],
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
    if (mounted && location != null) _selectRoom(location);
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
      cleanLocationAttribute(_selectedAttributes?['RefName']);

  String get _selectedRoomInfo =>
      cleanLocationAttribute(_selectedAttributes?['MothersRoomInfo']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.maybePop(context)),
        title: const Text(
          'Lactation Rooms',
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
                      onPressed: _isLoading ? null : _browseRooms,
                      icon: const Icon(Icons.list),
                      label: const Text('Browse rooms'),
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
                  LactationRoomInfoCard(
                    buildingName: _selectedBuildingName,
                    roomInfo: _selectedRoomInfo,
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
              "The lactation rooms map couldn't be loaded. "
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
