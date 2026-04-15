import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';

class SomosCampusMap extends StatefulWidget {
  const SomosCampusMap({super.key});

  @override
  State<SomosCampusMap> createState() => _SomosCampusMapState();
}

class _SomosCampusMapState extends State<SomosCampusMap> {
  late ArcGISMapViewController _mapController;
  late FeatureLayer _featureLayer;
  Map<String, dynamic>? _selectedAttributes;
  bool _showFullInfo = false;

  @override
  void initState() {
    super.initState();

    // Location is manually set to the Sac State campus.
    // TODO: Update BasemapStyle to client's desired base map.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.openStreets)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 38.56091,
        longitude: -121.42405,
        scale: 10000,
      );

    //Feature layer is how we get location pins onto the map.
    _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(
          "https://services5.arcgis.com/54falWtcpty3V47Z/arcgis/rest/services/City_of_Sacramento_Community_Centers/FeatureServer/0",
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

    setState(() {
      _selectedAttributes = result.geoElements.firstOrNull?.attributes;
      _showFullInfo = false;
    });
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

  void _clearSelection() {
    setState(() {
      _selectedAttributes = null;
      _showFullInfo = false;
    });
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
            if (_selectedAttributes != null) _buildLocationInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard() {
    final String cardTitle =
        _selectedAttributes?['FACILITY_NAME']?.toString() ?? 'Location Info';

    final String address =
        _selectedAttributes?['ADDRESS']?.toString() ??
        _selectedAttributes?['LOCATION']?.toString() ??
        'Address not available';

    final String category =
        _selectedAttributes?['CATEGORY']?.toString() ?? 'N/A';

    final String type = _selectedAttributes?['TYPE']?.toString() ?? 'N/A';

    final String website =
        _selectedAttributes?['WEBSITE']?.toString() ??
        _selectedAttributes?['URL']?.toString() ??
        '';

    final String phone =
        _selectedAttributes?['PHONE']?.toString() ?? 'N/A';

    final String email =
        _selectedAttributes?['EMAIL']?.toString() ?? 'Email not available';

    final String description =
        _selectedAttributes?['DESCRIPTION']?.toString() ??
        _selectedAttributes?['DETAILS']?.toString() ??
        'No description available.';

    final String? imageUrl =
        _selectedAttributes?['IMAGE_URL']?.toString();

    // Create social media links map
    final Map<String, String> socialLinks = {};
    if (_selectedAttributes?['INSTAGRAM_URL'] != null) {
      socialLinks['instagram'] = _selectedAttributes?['INSTAGRAM_URL']?.toString() ?? '';
    }
    if (_selectedAttributes?['FACEBOOK_URL'] != null) {
      socialLinks['facebook'] = _selectedAttributes?['FACEBOOK_URL']?.toString() ?? '';
    }
    if (_selectedAttributes?['TWITTER_URL'] != null) {
      socialLinks['twitter'] = _selectedAttributes?['TWITTER_URL']?.toString() ?? '';
    }
    
    // Add demo social media links for testing (remove once real data is available)
    if (socialLinks.isEmpty) {
      socialLinks['instagram'] = 'https://instagram.com/somoscampus';
      socialLinks['facebook'] = 'https://facebook.com/somoscampus';
      socialLinks['twitter'] = 'https://twitter.com/somoscampus';
    }

    return LocationInfoCard(
      cardTitle: cardTitle,
      address: address,
      category: category,
      type: type,
      website: website,
      phone: phone,
      email: email,
      description: description,
      imageUrl: imageUrl,
      showFullInfo: _showFullInfo,
      onClose: _clearSelection,
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
      socialLinks: socialLinks,
    );
  }
}
