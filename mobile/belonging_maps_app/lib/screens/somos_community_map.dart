import 'dart:async';

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/constants/map_icon_config.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import '/widgets/current_location_buttons.dart';
import '/widgets/map_search_bar.dart';
import '/widgets/map_layers_button.dart';
import '/services/layer_search.dart';
import '/services/layer_filter.dart';
import '/services/current_location.dart';
import '/services/map_icon_renderer.dart';

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

  /// Holds the enlarged icon drawn on top of the currently selected feature.
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();

  /// The map's categories and their per-type filter state. Initialized in
  /// [initState] so the type selections persist while the screen is alive.
  late final List<MapLayerEntry> _layerEntries;

  List<FeatureLayer> get _layers =>
      _layerEntries.map((entry) => entry.layer).toList();

  /// Pairs each layer with the icon configuration used to render it.
  List<LayerIconAssignment> get _layerAssignments => [
        LayerIconAssignment(
          layer: _somosBusinessesLayer,
          config: somosLayerIcons['businesses']!,
        ),
        LayerIconAssignment(
          layer: _somosReligionLayer,
          config: somosLayerIcons['religion']!,
        ),
        LayerIconAssignment(
          layer: _somosFoodLayer,
          config: somosLayerIcons['food']!,
        ),
        LayerIconAssignment(
          layer: _somosPublicArtsLayer,
          config: somosLayerIcons['publicArts']!,
        ),
        LayerIconAssignment(
          layer: _somosCommunityServicesLayer,
          config: somosLayerIcons['communityServices']!,
        ),
        LayerIconAssignment(
          layer: _somosEducationLayer,
          config: somosLayerIcons['education']!,
        ),
      ];

  /// Looks up the icon configuration for a tapped layer.
  Map<FeatureLayer, LayerIconConfig> get _layerConfigs =>
      {for (final assignment in _layerAssignments) assignment.layer: assignment.config};

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

    _layerEntries = [
      MapLayerEntry(
        label: 'Businesses',
        layer: _somosBusinessesLayer,
        config: somosLayerIcons['businesses'],
      ),
      MapLayerEntry(
        label: 'Religion',
        layer: _somosReligionLayer,
        config: somosLayerIcons['religion'],
      ),
      MapLayerEntry(
        label: 'Food',
        layer: _somosFoodLayer,
        config: somosLayerIcons['food'],
      ),
      MapLayerEntry(
        label: 'Public Arts',
        layer: _somosPublicArtsLayer,
        config: somosLayerIcons['publicArts'],
      ),
      MapLayerEntry(
        label: 'Community Services',
        layer: _somosCommunityServicesLayer,
        config: somosLayerIcons['communityServices'],
      ),
      MapLayerEntry(
        label: 'Education',
        layer: _somosEducationLayer,
        config: somosLayerIcons['education'],
      ),
    ];

    map.operationalLayers.addAll(_layers);

    _mapController = ArcGISMapView.createController()..arcGISMap = map;
    _mapController.graphicsOverlays.addAll([_userOverlay, _selectionOverlay]);

    unawaited(applyLayerIconRenderers(_layerAssignments));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Recomputes every layer's definition expression from the current type
  /// filters and search text, so the two combine (AND) instead of overwriting
  /// each other.
  Future<void> _applyFilters() async {
    for (final entry in _layerEntries) {
      final typeClause = buildTypeClause(entry.types, entry.selectedTypes);
      final searchClause =
          await buildLayerSearchClause(entry.layer, _searchController.text);

      final clauses = <String>[
        if (typeClause.isNotEmpty) typeClause,
        if (searchClause.isNotEmpty) '($searchClause)',
      ];
      entry.layer.definitionExpression = clauses.join(' AND ');
    }
  }

  Future<void> _getCurrentLocation() {
    return showCurrentLocation(_mapController, _userOverlay);
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    Map<String, dynamic>? newAttributes;
    String? newCategory;
    Geometry? newGeometry;
    LayerIconConfig? newIconConfig;

    for (final entry in _layerEntries) {
      if (!entry.layer.isVisible) continue;

      final result = await _mapController.identifyLayer(
        entry.layer,
        screenPoint: screenPoint,
        tolerance: 10.0,
        maximumResults: 1,
      );

      if (result.geoElements.isNotEmpty) {
        final element = result.geoElements.first;
        newAttributes = element.attributes;
        newGeometry = element.geometry;
        newCategory = entry.label;
        newIconConfig = _layerConfigs[entry.layer];
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

      if (newIconConfig != null) {
        await showSelectedFeature(
          mapController: _mapController,
          selectionOverlay: _selectionOverlay,
          geometry: newGeometry,
          iconAssetPath: iconAssetPathForType(
            newIconConfig,
            newAttributes[mapIconTypeField],
          ),
        );
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

    clearSelectedFeature(_selectionOverlay);

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
                onChanged: (_) => unawaited(_applyFilters()),
              ),
            ),
            const SizedBox(width: 12),
            MapLayersButton(
              entries: _layerEntries,
              onFilterChanged: () => unawaited(_applyFilters()),
            ),
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