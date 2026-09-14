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

class UbuntuCommunityMap extends StatefulWidget {
  const UbuntuCommunityMap({super.key});

  @override
  State<UbuntuCommunityMap> createState() => _UbuntuCommunityMapState();
}

class _UbuntuCommunityMapState extends State<UbuntuCommunityMap> {
  static const double _mapControlPadding = 16;
  static const double _zoomControlWidth = 72;

  late ArcGISMapViewController _mapController;

  late FeatureLayer _ubuntuBusinessesLayer;
  late FeatureLayer _ubuntuCommunityServicesLayer;
  late FeatureLayer _ubuntuReligiousLayer;
  late FeatureLayer _ubuntuEducationLayer;

  bool _showUbuntuBusinesses = true;
  bool _showUbuntuCommunityServices = true;
  bool _showUbuntuReligious = true;
  bool _showUbuntuEducation = true;

  Map<String, dynamic>? _selectedAttributes;
  String? _selectedCategory;
  bool _showFullInfo = false;
  bool _showInfoCard = false;

  final TextEditingController _searchController = TextEditingController();

  final GraphicsOverlay _userOverlay = GraphicsOverlay();

  List<MapLayerEntry> get _layerEntries => [
        MapLayerEntry(label: 'Businesses', layer: _ubuntuBusinessesLayer),
        MapLayerEntry(
          label: 'Community Services',
          layer: _ubuntuCommunityServicesLayer,
        ),
        MapLayerEntry(label: 'Religious', layer: _ubuntuReligiousLayer),
        MapLayerEntry(label: 'Education', layer: _ubuntuEducationLayer),
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

    _ubuntuBusinessesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UBUNTU_BUSINESSES_URL'] ?? ''),
      ),
    )..isVisible = _showUbuntuBusinesses;

    _ubuntuCommunityServicesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UBUNTU_COMMUNITY_SERVICES_URL'] ?? ''),
      ),
    )..isVisible = _showUbuntuCommunityServices;

    _ubuntuReligiousLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UBUNTU_RELIGIOUS_URL'] ?? ''),
      ),
    )..isVisible = _showUbuntuReligious;

    _ubuntuEducationLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['UBUNTU_EDUCATION_URL'] ?? ''),
      ),
    )..isVisible = _showUbuntuEducation;

    map.operationalLayers.addAll([
      _ubuntuBusinessesLayer,
      _ubuntuCommunityServicesLayer,
      _ubuntuReligiousLayer,
      _ubuntuEducationLayer,
    ]);

    _mapController = ArcGISMapView.createController()..arcGISMap = map;
    _mapController.graphicsOverlays.add(_userOverlay);
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

  for (final result in results) {
    if (result.geoElements.isNotEmpty) {
      newAttributes = result.geoElements.first.attributes;

      for (final entry in _layerEntries) {
        if (identical(entry.layer, result.layerContent)) {
          newCategory = entry.label;
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

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        _selectedAttributes = null;
        _selectedCategory = null;
        _showFullInfo = false;
      });
    });
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
