import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';

class SomosCommunityMap extends StatefulWidget {
  const SomosCommunityMap({super.key});

  @override
  State<SomosCommunityMap> createState() => _SomosCommunityMapState();
}

class _SomosCommunityMapState extends State<SomosCommunityMap> {
  late ArcGISMapViewController _mapController;

  // Feature layers
  late FeatureLayer _somosBusinessesLayer;
  late FeatureLayer _somosReligionLayer;
  late FeatureLayer _somosFoodLayer;
  late FeatureLayer _somosPublicArtsLayer;
  late FeatureLayer _somosCommunityServicesLayer;
  late FeatureLayer _somosEducationLayer;

  // Control visibility of layers
  bool _showSomosBusinesses = true;
  bool _showSomosReligion = true;
  bool _showSomosFood = true;
  bool _showSomosPublicArts = true;
  bool _showSomosCommunityServices = true;
  bool _showSomosEducation = true;

  Map<String, dynamic>? _selectedAttributes;
  bool _showFullInfo = false;
  bool _showInfoCard = false;

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
    )..isVisible = _showSomosBusinesses;

    _somosReligionLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_RELIGION_URL'] ?? ''),
      ),
    )..isVisible = _showSomosReligion;

    _somosFoodLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_FOOD_URL'] ?? ''),
      ),
    )..isVisible = _showSomosFood;

    _somosPublicArtsLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_PUBLIC_ARTS_URL'] ?? ''),
      ),
    )..isVisible = _showSomosPublicArts;

    _somosCommunityServicesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_COMMUNITY_SERVICES_URL'] ?? ''),
      ),
    )..isVisible = _showSomosCommunityServices;

    _somosEducationLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(dotenv.env['SOMOS_EDUCATION_URL'] ?? ''),
      ),
    )..isVisible = _showSomosEducation;

    map.operationalLayers.addAll([
      _somosBusinessesLayer,
      _somosReligionLayer,
      _somosFoodLayer,
      _somosPublicArtsLayer,
      _somosCommunityServicesLayer,
      _somosEducationLayer,
    ]);

    _mapController = ArcGISMapView.createController()..arcGISMap = map;
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
  final results = await _mapController.identifyLayers(
    screenPoint: screenPoint,
    tolerance: 15.0,
    maximumResultsPerLayer: 1,
  );

  Map<String, dynamic>? newAttributes;

  for (final result in results) {
    if (result.geoElements.isNotEmpty) {
      newAttributes = result.geoElements.first.attributes;
      break;
    }
  }

  if (newAttributes != null) {
    final bool isReplacingExistingCard = _selectedAttributes != null;

    setState(() {
      _selectedAttributes = newAttributes;
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
            if (_selectedAttributes != null) _buildAnimatedLocationInfoCard(),
          ],
        ),
      ),
    );
  }
}
