import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import '/widgets/map_filter_button.dart';

class SomosCampusMap extends StatefulWidget {
  const SomosCampusMap({super.key});

  @override
  State<SomosCampusMap> createState() => _SomosCampusMapState();
}

class _SomosCampusMapState extends State<SomosCampusMap> {
  late ArcGISMapViewController _mapController;
  late FeatureLayer _featureLayer;

  Map<String, dynamic>? _selectedAttributes;
  double? _selectedLat;
  double? _selectedLng;
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

    _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(
          'https://services5.arcgis.com/54falWtcpty3V47Z/arcgis/rest/services/City_of_Sacramento_Community_Centers/FeatureServer/0',
        ),
      ),
    );

    map.operationalLayers.add(_featureLayer);
    _mapController = ArcGISMapView.createController()..arcGISMap = map;
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    final result = await _mapController.identifyLayer(
      _featureLayer,
      screenPoint: screenPoint,
      tolerance: 15.0,
      maximumResults: 1,
    );

    final geoElement = result.geoElements.firstOrNull;

    double? lat;
    double? lng;

    if (geoElement?.geometry is ArcGISPoint) {
      final point = geoElement!.geometry as ArcGISPoint;

      final ArcGISPoint wgsPoint;
      if (point.spatialReference?.wkid == 4326) {
        wgsPoint = point;
      } else {
        final projected = GeometryEngine.project(
          point,
          outputSpatialReference: SpatialReference.wgs84,
        );
        wgsPoint = projected as ArcGISPoint;
      }

      lat = wgsPoint.y;
      lng = wgsPoint.x;
    }

    if (geoElement?.attributes != null) {
      setState(() {
        _selectedAttributes = geoElement!.attributes;
        _selectedLat = lat;
        _selectedLng = lng;
        _showFullInfo = false;
        _showInfoCard = true;
      });
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
    final facilityName = _cleanField(_selectedAttributes?['FACILITY_NAME']);
    final address = _cleanField(_selectedAttributes?['ADDRESS']).isNotEmpty
        ? _cleanField(_selectedAttributes?['ADDRESS'])
        : _cleanField(_selectedAttributes?['LOCATION']).isNotEmpty
            ? _cleanField(_selectedAttributes?['LOCATION'])
            : 'Address not available';

    final category = _cleanField(_selectedAttributes?['CATEGORY']);
    final type = _cleanField(_selectedAttributes?['TYPE']);
    final phone = _cleanField(_selectedAttributes?['PHONE']);
    final description = _cleanField(_selectedAttributes?['DESCRIPTION']).isNotEmpty
        ? _cleanField(_selectedAttributes?['DESCRIPTION'])
        : _cleanField(_selectedAttributes?['DETAILS']);

    final imageUrl = _cleanField(_selectedAttributes?['IMAGE_URL']).isNotEmpty
        ? _cleanField(_selectedAttributes?['IMAGE_URL'])
        : null;

    final lowerName = facilityName.toLowerCase();
    final website = lowerName.contains('park')
        ? 'https://www.cityofsacramento.gov/ypce/parks'
        : 'https://www.cityofsacramento.gov/ypce/community-centers';

    final rawEmail = _cleanField(_selectedAttributes?['EMAIL']);
    final email =
        rawEmail.isNotEmpty ? rawEmail : 'info@cityofsacramento.org';

    return LocationInfoData(
      cardTitle: facilityName.isNotEmpty ? facilityName : 'Location Info',
      address: address,
      category: category,
      type: type,
      website: website,
      phone: phone,
      email: email,
      description: description,
      imageUrl: imageUrl,
      socialLinks: const {},
      locationLat: _selectedLat,
      locationLng: _selectedLng,
    );
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
            MapZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: MapFilterButton(
                  featureLayer: _featureLayer,
                  filterField: 'CATEGORY',
                  label: 'Category',
                ),
              ),
            ),
            if (_selectedAttributes != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _dismissLocationCard,
                  child: const SizedBox.expand(),
                ),
              ),
            if (_selectedAttributes != null) _buildAnimatedLocationInfoCard(),
          ],
        ),
      ),
    );
  }
}