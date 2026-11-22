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
import '/services/community_map_search.dart';
import '/services/current_location.dart';
import '/services/map_icon_renderer.dart';
import '/services/map_location_source.dart';
import '/services/map_tap_target.dart';
import '/widgets/map_location_browser.dart';
import '/widgets/search_suggestion_list.dart';

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
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedIconAsset;

  final TextEditingController _searchController = TextEditingController();
  CommunityMapSearchResult _searchResult = CommunityMapSearchResult.none;

  final GraphicsOverlay _userOverlay = GraphicsOverlay();

  /// Holds the enlarged icon drawn on top of the currently selected feature.
  final GraphicsOverlay _selectionOverlay = GraphicsOverlay();

  /// The map's categories and their per-type filter state. Initialized in
  /// [initState] so the type selections persist while the screen is alive.
  late final List<MapLayerEntry> _layerEntries;

  List<FeatureLayer> get _layers =>
      _layerEntries.map((entry) => entry.layer).toList();

  List<MapLocationSource> get _visibleLocationSources => _layerEntries
      .where((entry) => entry.layer.isVisible)
      .map(
        (entry) => arcGisLocationSource(name: entry.label, layer: entry.layer),
      )
      .toList();

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
  Map<FeatureLayer, LayerIconConfig> get _layerConfigs => {
    for (final assignment in _layerAssignments)
      assignment.layer: assignment.config,
  };

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

  /// Shared search (P1-328): filters the layers by name, category and
  /// address, then loads suggestions for the search bar.
  late final CommunityMapSearch _search = CommunityMapSearch.forLayers(
    _layerEntries,
  );

  Future<void> _onSearchChanged(String query) async {
    final result = await _search.search(query);
    if (!mounted || result == null) return;
    setState(() => _searchResult = result);
  }

  Future<void> _getCurrentLocation() {
    return showCurrentLocation(context, _mapController, _userOverlay);
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    final results = await _mapController.identifyLayers(
      screenPoint: screenPoint,
      tolerance: mapIconTapTolerance(mapIconSize),
      maximumResultsPerLayer: 5,
    );

    if (!mounted) return;

    final candidates = <MapTapCandidate<VoidCallback>>[];

    // The enlarged icon of the selected location is drawn above the feature
    // icons, so a tap on it keeps the card that is already open.
    if (_selectedAttributes != null) {
      final selectionResult = await _mapController.identifyGraphicsOverlay(
        _selectionOverlay,
        screenPoint: screenPoint,
        tolerance: mapIconTapTolerance(selectedMapIconSize),
        maximumResults: 1,
      );

      if (!mounted) return;

      for (final graphic in selectionResult.graphics) {
        final position = mapGeometryScreenPoint(
          _mapController,
          graphic.geometry,
        );
        if (position == null) continue;

        candidates.add(
          MapTapCandidate(
            value: () {},
            screenPoint: position,
            tolerance: mapIconTapTolerance(selectedMapIconSize),
          ),
        );
      }
    }

    // Identify results follow the draw order of the operational layers
    // (bottom-to-top), so they are reversed to keep candidates top-most first.
    for (final result in results.reversed) {
      final entry = _layerEntries
          .where((entry) => identical(entry.layer, result.layerContent))
          .firstOrNull;
      if (entry == null) continue;

      for (final element in result.geoElements) {
        final attributes = element.attributes;
        if (attributes.isEmpty) continue;

        final position = mapGeometryScreenPoint(
          _mapController,
          element.geometry,
        );
        if (position == null) continue;

        candidates.add(
          MapTapCandidate(
            value: () => unawaited(
              _selectLocation(
                attributes: attributes,
                category: entry.label,
                iconConfig: _layerConfigs[entry.layer],
                geometry: element.geometry,
              ),
            ),
            screenPoint: position,
            tolerance: mapIconTapTolerance(mapIconSize),
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
  }

  /// Shows the info card for a tapped location and enlarges its icon.
  Future<void> _selectLocation({
    required Map<String, dynamic> attributes,
    required String category,
    required LayerIconConfig? iconConfig,
    required Geometry? geometry,
  }) async {
    final bool replacing = _selectedAttributes != null;
    final point = wgs84Point(geometry);
    final iconAsset = iconConfig == null
        ? null
        : iconAssetPathForType(iconConfig, attributes[mapIconTypeField]);

    setState(() {
      _selectedAttributes = attributes;
      _selectedCategory = category;
      _selectedLat = point?.y;
      _selectedLng = point?.x;
      _selectedIconAsset = iconAsset;
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

    if (iconConfig != null) {
      await showSelectedFeature(
        mapController: _mapController,
        selectionOverlay: _selectionOverlay,
        geometry: geometry,
        iconAssetPath: iconAssetPathForType(
          iconConfig,
          attributes[mapIconTypeField],
        ),
      );
    }
  }

  Future<void> _browseLocations() async {
    final location = await showMapLocationBrowser(
      context,
      _visibleLocationSources,
    );
    if (!mounted || location == null) return;
    _showLocation(
      location.attributes,
      location.category,
      geometry: location.geometry,
    );
  }

  Future<void> _selectSearchSuggestion(MapLocation location) async {
    _searchController.text = location.name;
    await _onSearchChanged(location.name);
    if (!mounted) return;
    setState(() => _searchResult = CommunityMapSearchResult.none);
    await _showLocation(
      location.attributes,
      location.category,
      geometry: location.geometry,
    );
  }

  Future<void> _showLocation(
    Map<String, dynamic> attributes,
    String category, {
    Geometry? geometry,
  }) async {
    LayerIconConfig? iconConfig;
    for (final entry in _layerEntries) {
      if (entry.label == category) {
        iconConfig = _layerConfigs[entry.layer];
        break;
      }
    }

    final replacing = _selectedAttributes != null;
    final point = wgs84Point(geometry);
    final iconAsset = iconConfig == null
        ? null
        : iconAssetPathForType(iconConfig, attributes[mapIconTypeField]);

    setState(() {
      _selectedAttributes = attributes;
      _selectedCategory = category;
      _selectedLat = point?.y;
      _selectedLng = point?.x;
      _selectedIconAsset = iconAsset;
      _showFullInfo = false;
      _showInfoCard = replacing;
    });

    if (!replacing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedAttributes == null) return;
        setState(() => _showInfoCard = true);
      });
    }

    if (iconConfig != null) {
      await showSelectedFeature(
        mapController: _mapController,
        selectionOverlay: _selectionOverlay,
        geometry: geometry,
        iconAssetPath: iconAssetPathForType(
          iconConfig,
          attributes[mapIconTypeField],
        ),
      );
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
        _selectedLat = null;
        _selectedLng = null;
        _selectedIconAsset = null;
        _showFullInfo = false;
      });
    });
  }

  Widget _buildLocationInfoCard() {
    final data = LocationInfoData.fromAttributes(
      _selectedAttributes,
      fallbackCategory: _selectedCategory,
      locationLat: _selectedLat,
      locationLng: _selectedLng,
      orgLogo: _selectedIconAsset,
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
                onChanged: (query) => unawaited(_onSearchChanged(query)),
                noResultsMessage: _searchResult.noResultsMessage,
                suggestions: _searchResult.suggestions
                    .map(
                      (location) => SearchSuggestion(
                        title: location.name,
                        subtitle: location.category,
                        onSelected: () {
                          unawaited(_selectSearchSuggestion(location));
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(width: 12),
            MapLayersButton(
              entries: _layerEntries,
              onFilterChanged: () =>
                  unawaited(_onSearchChanged(_searchController.text)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: 'SOMOS Community Map',
      showBackButton: true,
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
            if (_selectedAttributes == null)
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
            if (_selectedAttributes != null) _buildAnimatedLocationInfoCard(),
          ],
        ),
      ),
    );
  }
}
