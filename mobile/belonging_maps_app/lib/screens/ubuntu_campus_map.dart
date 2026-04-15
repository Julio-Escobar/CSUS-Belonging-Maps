import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class UbuntuCampusMap extends StatefulWidget {
  const UbuntuCampusMap({super.key});

  @override
  State<UbuntuCampusMap> createState() => _UbuntuCampusMapState();
}

class _UbuntuCampusMapState extends State<UbuntuCampusMap> {
  late ArcGISMapViewController _mapController;
  late FeatureLayer _featureLayer;
  Map<String, dynamic>? _selectedAttributes;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapController,
            onTap: _handleMapTap,
          ),
          if (_selectedAttributes != null) _buildCard(),
        ],
      ),
    );
  }

  Widget _buildCard() {
    String cardTitle = _selectedAttributes?['FACILITY_NAME']?.toString() ?? 'Location Info';

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
                  onPressed: () => setState(() => _selectedAttributes = null)),
              ),
              Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}