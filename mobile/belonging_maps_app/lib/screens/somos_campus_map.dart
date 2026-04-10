import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class SomosCampusMap extends StatelessWidget {
  const SomosCampusMap({super.key});


@override
  Widget build(BuildContext context) {

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.openStreets)
      // Set location here. Scale is zoom (bigger number is less zoom).
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 38.56091,   
        longitude: -121.42405, 
        scale: 10000,
      );

    //Replace layerURL with the URL of desired feature layer. Placeholder: Community Centers in Sacramento        
    final String layerURL = "https://services5.arcgis.com/54falWtcpty3V47Z/arcgis/rest/services/City_of_Sacramento_Community_Centers/FeatureServer/0";
    final featureTable = ServiceFeatureTable.withUri(Uri.parse(layerURL));
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);

    map.operationalLayers.add(featureLayer);

      return Scaffold(
        body: ArcGISMapView(
        controllerProvider: () => ArcGISMapView.createController()
          ..arcGISMap = map,
          ),
      );
  }
}