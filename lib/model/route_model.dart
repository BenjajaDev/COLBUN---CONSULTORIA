import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart'; // 1. IMPORTA HIVE

part 'route_model.g.dart'; // 2. AÑADE ESTA LÍNEA (dará error por ahora)

@HiveType(typeId: 0) // 3. ID ÚNICO (0 PARA ESTA CLASE)
class MapRoute {
  
  @HiveField(0) // 4. ANOTA LOS CAMPOS
  final String id;
  
  @HiveField(1)
  final double initialLatitude;
  
  @HiveField(2)
  final double initialLongitude;
  
  @HiveField(3)
  final double finalLatitude;
  
  @HiveField(4)
  final double finalLongitude;
  
  @HiveField(5)
  final String name;
  
  @HiveField(6)
  final String? category; // Hive maneja nulos (String?)
  
  @HiveField(7)
  final double? distanceKm; // Hive maneja nulos (double?)
  
  @HiveField(8)
  final String? season; // Hive maneja nulos (String?)
  
  @HiveField(9)
  final List<POI> pois; // ¡Funciona! porque POI ya es un HiveType
  
  @HiveField(10)
  final List<LatLng> geometry; // Hive usará el "traductor" que haremos

  MapRoute({
    required this.id,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.finalLatitude,
    required this.finalLongitude,
    required this.name,
    required this.pois,
    required this.geometry,
    this.category,
    this.distanceKm,
    this.season,
  });

  // El método copyWith no necesita anotaciones
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
      pois: pois ?? this.pois,
      // (Corregí un pequeño error aquí, antes tenías geometry: [])
      geometry: geometry ?? this.geometry, 
    );
  }
}