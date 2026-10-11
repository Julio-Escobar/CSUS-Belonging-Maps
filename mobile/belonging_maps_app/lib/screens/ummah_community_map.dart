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

class UmmahCommunityMap extends StatefulWidget {
  const UmmahCommunityMap({super.key});

  @override
  State<UmmahCommunityMap> createState() => _UmmahCommunityMapState();
}

class _UmmahCommunityMapState extends State<UmmahCommunityMap> {
  static const double _mapControlPadding = 16;
  static const double _zoomControlWidth = 72;

  late ArcGISMapViewController _mapController;

  late FeatureLayer _ummahBusinessServicesLayer;
  late FeatureLayer _ummahCommunityServicesLayer;
  late FeatureLayer _ummahHalalFoodsLayer;
  late FeatureLayer _ummahReligiousCulturalLayer;
  late FeatureLayer _ummahEducationLayer;

  bool _showUmmahBusinessServices = true;
  bool _showUmmahCommunityServices = true;
  bool _showUmmahHalalFoods = true;
  bool _showUmmahReligiousCultural = true;
  bool _showUmmahEducation = true;

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

  /// Pairs each layer with the icon configuration used to render it.
  List<LayerIconAssignment> get _layerAssignments => [
        LayerIconAssignment(
          layer: _ummahBusinessServicesLayer,
          config: ummahLayerIcons['businessServices']!,
        ),
        LayerIconAssignment(
          layer: _ummahCommunityServicesLayer,
          config: ummahLayerIcons['communityServices']!,
        ),
        LayerIconAssignment(
          layer: _ummahHalalFoodsLayer,
          config: ummahLayerIcons['halalFoods']!,
        ),
        LayerIconAssignment(
          layer: _ummahReligiousCulturalLayer,
          config: ummahLayerIcons['religiousCultural']!,
        ),
        LayerIconAssignment(
          layer: _ummahEducationLayer,
          config: ummahLayerIcons['education']!,
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

    _ummahBusinessServicesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UMMAH_BUSINESS_SERVICES_URL'] ?? ''),
      ),
    )..isVisible = _showUmmahBusinessServices;

    _ummahCommunityServicesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UMMAH_COMMUNITY_SERVICES_URL'] ?? ''),
      ),
    )..isVisible = _showUmmahCommunityServices;

    _ummahHalalFoodsLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UMMAH_HALAL_FOODS_URL'] ?? ''),
      ),
    )..isVisible = _showUmmahHalalFoods;

    _ummahReligiousCulturalLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UMMAH_RELIGIOUS_CULTURAL_URL'] ?? ''),
      ),
    )..isVisible = _showUmmahReligiousCultural;

    _ummahEducationLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UMMAH_EDUCATION_URL'] ?? ''),
      ),
    )..isVisible = _showUmmahEducation;

    _layerEntries = [
      MapLayerEntry(
        label: 'Business Services',
        layer: _ummahBusinessServicesLayer,
        config: ummahLayerIcons['businessServices'],
      ),
      MapLayerEntry(
        label: 'Community Services',
        layer: _ummahCommunityServicesLayer,
        config: ummahLayerIcons['communityServices'],
      ),
      MapLayerEntry(
        label: 'Halal Foods',
        layer: _ummahHalalFoodsLayer,
        config: ummahLayerIcons['halalFoods'],
      ),
      MapLayerEntry(
        label: 'Religious & Cultural',
        layer: _ummahReligiousCulturalLayer,
        config: ummahLayerIcons['religiousCultural'],
      ),
      MapLayerEntry(
        label: 'Education',
        layer: _ummahEducationLayer,
        config: ummahLayerIcons['education'],
      ),
    ];

    map.operationalLayers.addAll([
      _ummahBusinessServicesLayer,
      _ummahCommunityServicesLayer,
      _ummahEducationLayer,
      _ummahHalalFoodsLayer,
      _ummahReligiousCulturalLayer,
    ]);

    _mapController = ArcGISMapView.createController()..arcGISMap = map;
    _mapController.graphicsOverlays.addAll([_userOverlay, _selectionOverlay]);

    unawaited(applyLayerIconRenderers(_layerAssignments));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    final results = await _mapController.identifyLayers(
      screenPoint: screenPoint,
      tolerance: 15.0,
      maximumResultsPerLayer: 1,
    );

    Map<String, dynamic>? newAttributes;
    String? newCategory;
    Geometry? newGeometry;
    LayerIconConfig? newIconConfig;

    for (final result in results) {
      if (result.geoElements.isNotEmpty) {
        final element = result.geoElements.first;
        newAttributes = element.attributes;
        newGeometry = element.geometry;

        for (final entry in _layerEntries) {
          if (identical(entry.layer, result.layerContent)) {
            newCategory = entry.label;
            newIconConfig = _layerConfigs[entry.layer];
            break;
          }
        }
        break;
      }
    }

    if (newAttributes != null) {
      final bool isReplacingExistingCard = _selectedAttributes != null;

      setState(() {
        _selectedAttributes = newAttributes;
        _selectedCategory = newCategory;
        _showFullInfo = false;
        _showInfoCard = isReplacingExistingCard;
      });

      if (!isReplacingExistingCard) {
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

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        _selectedAttributes = null;
        _selectedCategory = null;
        _showFullInfo = false;
      });
    });
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

  Widget _buildLocationInfoCard() {
    final data = LocationInfoData.fromAttributes(
      _selectedAttributes,
      fallbackCategory: _selectedCategory,
    );

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
