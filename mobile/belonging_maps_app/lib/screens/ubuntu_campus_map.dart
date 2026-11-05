import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '/widgets/map_filter_button.dart';
import '/widgets/map_search_bar.dart';
import '/widgets/search_suggestion_list.dart';
import '/services/map_location_source.dart';
import '/widgets/map_location_browser.dart';
import '/services/layer_search.dart';
import '/widgets/map_zoom_controls.dart';
import '/widgets/hamburger_menu.dart';

class UbuntuCampusMap extends StatefulWidget {
  const UbuntuCampusMap({super.key});

  @override
  State<UbuntuCampusMap> createState() => _UbuntuCampusMapState();
}

class _UbuntuCampusMapState extends State<UbuntuCampusMap> {
  late ArcGISMapViewController _mapController;
  late FeatureLayer _featureLayer;
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _selectedAttributes;
  List<MapLocation> _searchSuggestions = const [];
  int _suggestionRequest = 0;

  MapLocationSource get _locationSource =>
      arcGisLocationSource(name: 'Campus locations', layer: _featureLayer);

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

  Future<void> _onSearchChanged(String query) async {
    final request = ++_suggestionRequest;
    final searchClause = await buildLayerSearchClause(_featureLayer, query);
    _featureLayer.definitionExpression = searchClause;
    if (query.trim().isEmpty) {
      if (mounted && request == _suggestionRequest) {
        setState(() => _searchSuggestions = const []);
      }
      return;
    }

    final suggestions = await loadMapLocationSuggestions([
      _locationSource,
    ], query: query);
    if (!mounted || request != _suggestionRequest) return;
    setState(() => _searchSuggestions = suggestions);
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
    final location = await showMapLocationBrowser(context, [_locationSource]);
    if (!mounted || location == null) return;
    setState(() => _selectedAttributes = location.attributes);
  }

  Future<void> _selectSearchSuggestion(MapLocation location) async {
    _searchController.text = location.name;
    await _onSearchChanged(location.name);
    if (!mounted) return;
    setState(() {
      _searchSuggestions = const [];
      _selectedAttributes = location.attributes;
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
            MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
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
                        suggestions: _searchSuggestions
                            .map(
                              (location) => SearchSuggestion(
                                title: location.name,
                                subtitle: location.category,
                                onSelected: () {
                                  _selectSearchSuggestion(location);
                                },
                              ),
                            )
                            .toList(growable: false),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    String cardTitle =
        _selectedAttributes?['FACILITY_NAME']?.toString() ?? 'Location Info';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(maxHeight: 400),
        margin: EdgeInsets.all(20.0),
        child: Card(
          elevation: 8,
          color: Color(0xFF2F5F3E),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/ubuntu_logo_temp.png'),
                ),
                title: Text(
                  cardTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                trailing: CloseButton(
                  color: Colors.white,
                  onPressed: () => setState(() => _selectedAttributes = null),
                ),
              ),
              Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
