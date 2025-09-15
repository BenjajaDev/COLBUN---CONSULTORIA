

import 'package:consultoria_chat_bot/model/poi_model.dart';

class MapRoute{
  final String id;
  final double initialLatitude;
  final double initialLongitude;
  final double finalLatitude;
  final double finalLongitude;
  final String name;
  final List<POI> pois;
  MapRoute({
    required this.id,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.finalLatitude,
    required this.finalLongitude,
    required this.name,
    required this.pois,
  });
}