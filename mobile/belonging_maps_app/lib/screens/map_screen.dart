import 'package:flutter/material.dart';
import 'somos_campus_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _CampusMapsScreenState();
}

class _CampusMapsScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return const SomosCampusMap();
  }
}