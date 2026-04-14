import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class SomosCampusMap extends StatefulWidget {
  const SomosCampusMap({super.key});

  @override
  State<SomosCampusMap> createState() => _SomosCampusMapState();
}

class _SomosCampusMapState extends State<SomosCampusMap> {
  late ArcGISMapViewController _mapController;
  late FeatureLayer _featureLayer;
  Map<String, dynamic>? _selectedAttributes;

  // TODO: When real ArcGIS feature service URLs are provided by the client,
  // replace this single layer with one FeatureLayer per category,
  // and hook each layer's isVisible to its corresponding toggle.
  final Map<String, bool> _categoryToggles = {
    'Businesses': true,
    'Community Services': true,
    'Education': true,
    'Food': true,
    'Public Art Artists': true,
    'Religion': true,
    
  };

  @override
  void initState() {
    super.initState();

    //Location is manually set to the Sac State campus.
    //TODO: Update BasemapStyle to client's desired base map.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.openStreets)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 38.56091,
        longitude: -121.42405,
        scale: 10000,
      );

    //Feature layer is how we get location pins onto the map.
    //TODO: Replace with real client feature service URLs, one per category.
    _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(Uri.parse(
        "https://services5.arcgis.com/54falWtcpty3V47Z/arcgis/rest/services/City_of_Sacramento_Community_Centers/FeatureServer/0"
      ))
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
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Locations',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A4A2E),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _categoryToggles.updateAll((key, value) => true);
                          });
                          setState(() {});
                        },
                        child: const Text(
                          'Select All',
                          style: TextStyle(color: Color(0xFF1A4A2E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ..._categoryToggles.keys.map((category) {
                    return CheckboxListTile(
                      title: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A4A2E),
                        ),
                      ),
                      value: _categoryToggles[category],
                      activeColor: const Color(0xFF1A4A2E),
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setSheetState(() {
                          _categoryToggles[category] = val ?? true;
                        });
                        setState(() {
                          // TODO: When multiple feature layers are added,
                          // toggle the corresponding layer's visibility here.
                          // e.g. _foodLayer.isVisible = _categoryToggles['Food']!;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapController,
            onTap: _handleMapTap,
          ),

          // Filter toggle button
          Positioned(
            top: 60,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _showFilterSheet,
              tooltip: 'Filter locations',
              child: const Icon(
                Icons.filter_list_rounded,
                color: Color(0xFF1A4A2E),
              ),
            ),
          ),

          if (_selectedAttributes != null) _buildCard(),
        ],
      ),
    );
  }

  //TODO: Change field names to names of those in our client's map when we have access.
  Widget _buildCard() {
    String cardTitle = _selectedAttributes?['FACILITY_NAME']?.toString() ?? 'Location Info';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        margin: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 8,
          color: const Color(0xFF2F5F3E),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  cardTitle,
                  style: const TextStyle(
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
              const Divider(height: 1),
              //All other fields will begin here
            ],
          ),
        ),
      ),
    );
  }
}