import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import '/widgets/current_location_buttons.dart';
import '/widgets/map_search_bar.dart';
import '/widgets/map_layers_button.dart';
import '/services/layer_search.dart';
import '/services/current_location.dart';

class SomosCommunityMap extends StatefulWidget {
  const SomosCommunityMap({super.key});

  @override
  State<SomosCommunityMap> createState() => _SomosCommunityMapState();
}

class _SomosCommunityMapState extends State<SomosCommunityMap> {
  static const double _mapControlPadding = 16;
  static const double _zoomControlWidth = 72;

  late ArcGISMapViewController _mapController;

  late FeatureLayer _somosBusinessesLayer;
  late FeatureLayer _somosReligionLayer;
  late FeatureLayer _somosFoodLayer;
  late FeatureLayer _somosPublicArtsLayer;
  late FeatureLayer _somosCommunityServicesLayer;
  late FeatureLayer _somosEducationLayer;

  Map<String, dynamic>? _selectedAttributes;
  String? _selectedCategory;
  bool _showFullInfo = false;
  bool _showInfoCard = false;

  final TextEditingController _searchController = TextEditingController();

  final GraphicsOverlay _userOverlay = GraphicsOverlay();

  List<MapLayerEntry> get _layerEntries => [
        MapLayerEntry(label: 'Businesses', layer: _somosBusinessesLayer),
        MapLayerEntry(label: 'Religion', layer: _somosReligionLayer),
        MapLayerEntry(label: 'Food', layer: _somosFoodLayer),
        MapLayerEntry(label: 'Public Arts', layer: _somosPublicArtsLayer),
        MapLayerEntry(
          label: 'Community Services',
          layer: _somosCommunityServicesLayer,
        ),
        MapLayerEntry(label: 'Education', layer: _somosEducationLayer),
      ];

  List<FeatureLayer> get _layers =>
      _layerEntries.map((entry) => entry.layer).toList();

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

  Future<void> _getCurrentLocation() {
    return showCurrentLocation(_mapController, _userOverlay);
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    Map<String, dynamic>? newAttributes;
    String? newCategory;

    for (final entry in _layerEntries) {
      if (!entry.layer.isVisible) continue;

      final result = await _mapController.identifyLayer(
        entry.layer,
        screenPoint: screenPoint,
        tolerance: 10.0,
        maximumResults: 1,
      );

      if (result.geoElements.isNotEmpty) {
        newAttributes = result.geoElements.first.attributes;
        newCategory = entry.label;
        break;
      }
    }

    if (newAttributes != null) {
      final bool replacing = _selectedAttributes != null;

      setState(() {
        _selectedAttributes = newAttributes;
        _selectedCategory = newCategory;
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
        _selectedCategory = null;
        _showFullInfo = false;
      });
    });
  }

  Widget _buildLocationInfoCard() {
    final data = LocationInfoData.fromAttributes(
      _selectedAttributes,
      fallbackCategory: _selectedCategory,
    );

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
            Expanded(
              child: MapSearchBar(
                controller: _searchController,
                onChanged: (query) => applyLayerSearch(_layers, query),
              ),
            ),
            const SizedBox(width: 12),
            MapLayersButton(entries: _layerEntries),
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