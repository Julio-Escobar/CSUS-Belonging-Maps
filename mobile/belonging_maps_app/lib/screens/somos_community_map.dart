import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import '/widgets/current_location_buttons.dart';

class SomosCommunityMap extends StatefulWidget {
  const SomosCommunityMap({super.key});

  @override
  State<SomosCommunityMap> createState() => _SomosCommunityMapState();
}

class _SomosCommunityMapState extends State<SomosCommunityMap> {
  static const double _mapControlPadding = 16;
  static const double _zoomControlWidth = 72;
  static const double _futureFilterReservedWidth = 132;

  late ArcGISMapViewController _mapController;

  late FeatureLayer _somosBusinessesLayer;
  late FeatureLayer _somosReligionLayer;
  late FeatureLayer _somosFoodLayer;
  late FeatureLayer _somosPublicArtsLayer;
  late FeatureLayer _somosCommunityServicesLayer;
  late FeatureLayer _somosEducationLayer;

  Map<String, dynamic>? _selectedAttributes;
  bool _showFullInfo = false;
  bool _showInfoCard = false;

  final TextEditingController _searchController = TextEditingController();

  final GraphicsOverlay _userOverlay = GraphicsOverlay();

  List<FeatureLayer> get _layers => [
        _somosBusinessesLayer,
        _somosReligionLayer,
        _somosFoodLayer,
        _somosPublicArtsLayer,
        _somosCommunityServicesLayer,
        _somosEducationLayer,
      ];

  @override
  void initState() {
    super.initState();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.openStreets)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 38.56091,
        longitude: -121.42405,
        scale: 10000,
      );

    _somosBusinessesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_BUSINESSES_URL'] ?? ''),
      ),
    );

    _somosReligionLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_RELIGION_URL'] ?? ''),
      ),
    );

    _somosFoodLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_FOOD_URL'] ?? ''),
      ),
    );

    _somosPublicArtsLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_PUBLIC_ARTS_URL'] ?? ''),
      ),
    );

    _somosCommunityServicesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_COMMUNITY_SERVICES_URL'] ?? ''),
      ),
    );

    _somosEducationLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_EDUCATION_URL'] ?? ''),
      ),
    );

    map.operationalLayers.addAll(_layers);

    _mapController = ArcGISMapView.createController()..arcGISMap = map;
    _mapController.graphicsOverlays.add(_userOverlay);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String query) async {
    final escapedQuery = query.replaceAll("'", "''");

    if (escapedQuery.trim().isEmpty) {
      for (final layer in _layers) {
        layer.definitionExpression = '';
      }
      return;
    }

    final upperQuery = escapedQuery.toUpperCase();

    for (final layer in _layers) {
      if (layer.loadStatus != LoadStatus.loaded) {
        await layer.load();
      }

      final table = layer.featureTable;
      if (table == null) continue;

      final fields = table.fields
          .map((f) => f.name)
          .where((name) =>
              name.toUpperCase().contains("NAME") ||
              name.toUpperCase().contains("TITLE") ||
              name.toUpperCase().contains("FACILITY"))
          .toList();

      if (fields.isEmpty) continue;

      final conditions = fields
          .map((f) => "UPPER($f) LIKE '%$upperQuery%'")
          .join(" OR ");

      layer.definitionExpression = conditions;
    }
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    final point = ArcGISPoint(
      x: position.longitude,
      y: position.latitude,
      spatialReference: SpatialReference.wgs84,
    );

    final outerCircle = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle,
      color: Colors.blue.withOpacity(0.2),
      size: 28,
    );

    final innerCircle = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle,
      color: Colors.blue,
      size: 14,
    )
      ..outline = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid,
        color: Colors.white,
        width: 3,
      );

    final outerGraphic = Graphic(geometry: point, symbol: outerCircle);
    final innerGraphic = Graphic(geometry: point, symbol: innerCircle);

    _userOverlay.graphics.clear();
    _userOverlay.graphics.addAll([outerGraphic, innerGraphic]);

    await _mapController.setViewpointCenter(point, scale: 5000);
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    Map<String, dynamic>? newAttributes;

    for (final layer in _layers) {
      if (!layer.isVisible) continue;

      final result = await _mapController.identifyLayer(
        layer,
        screenPoint: screenPoint,
        tolerance: 10.0,
        maximumResults: 1,
      );

      if (result.geoElements.isNotEmpty) {
        newAttributes = result.geoElements.first.attributes;
        break;
      }
    }

    if (newAttributes != null) {
      final bool replacing = _selectedAttributes != null;

      setState(() {
        _selectedAttributes = newAttributes;
        _showFullInfo = false;
        _showInfoCard = replacing;
      });

      if (!replacing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _selectedAttributes == null) return;

          setState(() {
            _showInfoCard = true;
          });
        });
      }
    } else {
      _dismissLocationCard();
    }
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

    setState(() {
      _showInfoCard = false;
    });

    Future.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;

      setState(() {
        _selectedAttributes = null;
        _showFullInfo = false;
      });
    });
  }

  Widget _buildLocationInfoCard() {
    final data = LocationInfoData.fromAttributes(_selectedAttributes);

    return LocationInfoCard(
      data: data,
      showFullInfo: _showFullInfo,
      onClose: _dismissLocationCard,
      onShowMore: () => setState(() => _showFullInfo = true),
      onShowLess: () => setState(() => _showFullInfo = false),
    );
  }

  Widget _buildAnimatedLocationInfoCard() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      offset: _showInfoCard ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _showInfoCard ? 1 : 0,
        child: _buildLocationInfoCard(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: _searchController,
        onChanged: _applySearch,
        decoration: const InputDecoration(
          hintText: 'Search locations...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTopMapControls() {
    return Positioned(
      top: _mapControlPadding,
      left: _mapControlPadding,
      right: _mapControlPadding,
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: _zoomControlWidth),
            const SizedBox(width: 12),
            Expanded(child: _buildSearchBar()),
            const SizedBox(width: 12),
            const SizedBox(width: _futureFilterReservedWidth),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      body: Scaffold(
        body: Stack(
          children: [
            ArcGISMapView(
              controllerProvider: () => _mapController,
              onTap: _handleMapTap,
            ),
            MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
            _buildTopMapControls(),
            CurrentLocationButton(onPressed: _getCurrentLocation),
            if (_selectedAttributes != null) _buildAnimatedLocationInfoCard(),
          ],
        ),
      ),
    );
  }
}