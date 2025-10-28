import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:latlong2/latlong.dart';

class MapRoute {
  final String id;
  final double initialLatitude;
  final double initialLongitude;
  final double finalLatitude;
  final double finalLongitude;
  final String name;
  final String? category;
  final double? distanceKm;
  final String? season;
  final List<POI> pois;
  final List<LatLng> geometry;

  MapRoute({
    required this.id,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.finalLatitude,
    required this.finalLongitude,
    required this.name,
    required this.pois,
    required  this.geometry,
    this.category,
    this.distanceKm,
    this.season,
  });

  MapRoute copyWith({
    String? id,
    double? initialLatitude,
    double? initialLongitude,
    double? finalLatitude,
    double? finalLongitude,
    List<LatLng>? geometry,
    String? name,
    String? category,
    bool clearCategory = false,
    double? distanceKm,
    bool clearDistanceKm = false,
    String? season,
    bool clearSeason = false,
    List<POI>? pois,
  }) {
    return MapRoute(
      id: id ?? this.id,
      initialLatitude: initialLatitude ?? this.initialLatitude,
      initialLongitude: initialLongitude ?? this.initialLongitude,
      finalLatitude: finalLatitude ?? this.finalLatitude,
      finalLongitude: finalLongitude ?? this.finalLongitude,
      name: name ?? this.name,
      category: clearCategory ? null : (category ?? this.category),
      distanceKm: clearDistanceKm ? null : (distanceKm ?? this.distanceKm),
      season: clearSeason ? null : (season ?? this.season),
      pois: pois ?? this.pois, geometry: [],
    );
  }
}
