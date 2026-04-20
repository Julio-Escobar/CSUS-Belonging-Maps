import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/location_info_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SomosCommunityMap extends StatefulWidget {
  const SomosCommunityMap({super.key});

  @override
  State<SomosCommunityMap> createState() => _SomosCommunityMapState();
}

class _SomosCommunityMapState extends State<SomosCommunityMap> {
  late ArcGISMapViewController _mapController;
  
  //Feature layers
  late FeatureLayer _somosBusinessesLayer;
  late FeatureLayer _somosReligionLayer;
  late FeatureLayer _somosFoodLayer;
  late FeatureLayer _somosPublicArtsLayer;
  late FeatureLayer _somosCommunityServicesLayer;
  late FeatureLayer _somosEducationLayer;

  //Control visibility of layers
  bool _showSomosBusinesses = true;
  bool _showSomosReligion = true;
  bool _showSomosFood = true;
  bool _showSomosPublicArts = true;
  bool _showSomosCommunityServices = true;
  bool _showSomosEducation = true;

  Map<String, dynamic>? _selectedAttributes;
  bool _showFullInfo = false;

  @override
  void initState() {
    super.initState();

    // Location is manually set to the Sac State campus.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.openStreets)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 38.56091,
        longitude: -121.42405,
        scale: 10000,
      );

    //Feature layers added to the map.
    _somosBusinessesLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(
          dotenv.env['SOMOS_BUSINESSES_URL'] ?? '',
        ),
      ),
    )..isVisible = _showSomosBusinesses;

  _somosReligionLayer = FeatureLayer.withFeatureTable(
    ServiceFeatureTable.withUri(
      Uri.parse(
        dotenv.env['SOMOS_RELIGION_URL'] ?? '',
      ),
    ),
  )..isVisible = _showSomosReligion;

  _somosFoodLayer = FeatureLayer.withFeatureTable(
    ServiceFeatureTable.withUri(
      Uri.parse(
        dotenv.env['SOMOS_FOOD_URL'] ?? '',
      ),
    ),
  )..isVisible = _showSomosFood;

  _somosPublicArtsLayer = FeatureLayer.withFeatureTable(
    ServiceFeatureTable.withUri(
      Uri.parse(
        dotenv.env['SOMOS_PUBLIC_ARTS_URL'] ?? '',
      )
    )
  )..isVisible = _showSomosPublicArts;

  _somosCommunityServicesLayer = FeatureLayer.withFeatureTable(
    ServiceFeatureTable.withUri(
      Uri.parse(
        dotenv.env['SOMOS_COMMUNITY_SERVICES_URL'] ?? '',
      )
    )
  )..isVisible = _showSomosCommunityServices;

  _somosEducationLayer = FeatureLayer.withFeatureTable(
    ServiceFeatureTable.withUri(
      Uri.parse(
        dotenv.env['SOMOS_EDUCATION_URL'] ?? '',
      )
    )
  )..isVisible = _showSomosEducation;


    map.operationalLayers.addAll([_somosBusinessesLayer, _somosReligionLayer, _somosFoodLayer, _somosPublicArtsLayer, _somosCommunityServicesLayer, _somosEducationLayer]);
    _mapController = ArcGISMapView.createController()..arcGISMap = map;
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    final results = await _mapController.identifyLayers(
      screenPoint: screenPoint,
      tolerance: 15.0,
      maximumResultsPerLayer: 1,
    );

    Map<String, dynamic>? newAttributes;

    for (var result in results) {
      if (result.geoElements.isNotEmpty) {
        newAttributes = result.geoElements.first.attributes;
        break;
      }
    }

    setState(() {
      _selectedAttributes = newAttributes;
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
        _selectedAttributes?['Company_Name']?.toString() ??
        _selectedAttributes?['Name']?.toString() ??
         'Location Info';

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
    
    //TODO: Add demo social media links for testing (remove once real data is available)
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
