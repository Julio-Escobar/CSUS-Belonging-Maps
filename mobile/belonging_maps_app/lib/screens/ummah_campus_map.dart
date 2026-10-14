import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '/services/map_location_source.dart';
import '/widgets/map_filter_button.dart';
import '/widgets/map_search_bar.dart';
import '/services/layer_search.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';
import '/widgets/map_location_browser.dart';
import '/widgets/location_info_card.dart';

class UmmahCampusMap extends StatefulWidget {
  const UmmahCampusMap({super.key});

  @override
  State<UmmahCampusMap> createState() => _UmmahCampusMapState();
}

class _UmmahCampusMapState extends State<UmmahCampusMap> {
  late ArcGISMapViewController _mapController;
  late FeatureLayer _featureLayer;
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _selectedAttributes;
  bool _showFullInfo = false;

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
          "https://services5.arcgis.com/54falWtcpty3V47Z/arcgis/rest/services/City_of_Sacramento_Community_Centers/FeatureServer/0",
        ),
      ),
    );

    map.operationalLayers.add(_featureLayer);
    _mapController = ArcGISMapView.createController()..arcGISMap = map;
  }

  @override
    void dispose() {
      _searchController.dispose();
      super.dispose();
    }

    Future<void> _onSearchChanged(String query) {
      return applyLayerSearch([_featureLayer], query);
    }

  Future<void> _handleMapTap(Offset screenPoint) async {
    final result = await _mapController.identifyLayer(
      _featureLayer,
      screenPoint: screenPoint,
      tolerance: 15.0,
      maximumResults: 1,
    );

    if (!mounted) return;
    _showLocation(result.geoElements.firstOrNull?.attributes);
  }

  void _showLocation(Map<String, dynamic>? attributes) {
    setState(() {
      _selectedAttributes = attributes;
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

  Future<void> _browseLocations() async {
    final location = await showMapLocationBrowser(context, [
      arcGisLocationSource(name: 'Campus locations', layer: _featureLayer),
    ]);
    if (!mounted || location == null) return;
    _showLocation(location.attributes);
  }

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: 'Ummah Campus Map',
      body: Scaffold(
        body: Stack(
          children: [
            ArcGISMapView(
              controllerProvider: () => _mapController,
              onTap: _handleMapTap,
            ),
            MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 72),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MapSearchBar(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    MapFilterButton(
                      featureLayer: _featureLayer,
                      filterField: 'CATEGORY',
                      label: 'Category',
                    ),
                  ],
                ),
              ),
            ),
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
            if (_selectedAttributes != null) _buildCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return LocationInfoCard(
      data: LocationInfoData.fromAttributes(
        _selectedAttributes,
        fallbackCategory: 'Campus locations',
      ),
      showFullInfo: _showFullInfo,
      onClose: () => _showLocation(null),
      onShowMore: () => setState(() => _showFullInfo = true),
      onShowLess: () => setState(() => _showFullInfo = false),
    );
  }
}
