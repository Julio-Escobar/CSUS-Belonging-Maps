import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class SomosCampusMap extends StatelessWidget {
  const SomosCampusMap({super.key});


@override
  Widget build(BuildContext context) {
    return Scaffold(
      //Map with basemap option.
      body: ArcGISMapView(
        controllerProvider: () => ArcGISMapView.createController()
          ..arcGISMap = (ArcGISMap.withBasemapStyle(BasemapStyle.openStreets)
            //Set location here. Scale is zoom (bigger number is less zoom).
            ..initialViewpoint = Viewpoint.withLatLongScale(
              latitude: 38.56091,   
              longitude: -121.42405, 
              scale: 10000,         
            )),
      ),
    );
  }
}