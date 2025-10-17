import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:latlong2/latlong.dart';

const _noChange = Object();

/// 🔹 Estado base
abstract class MapState {}

/// Estado inicial (sin datos aún)
class MapInitial extends MapState {}

/// Estado cargando
class MapLoading extends MapState {}

/// Estado de error
class MapError extends MapState {
  final String message;
  MapError(this.message);
}

/// Estado cargado (mapa con rutas y filtros)
class MapLoaded extends MapState {
  final LatLng center;
  final List<LatLng> markers;
  final LatLng? userLocation;
  final double heading;
  final List<MapRoute> allRoutes;
  final List<MapRoute> filteredRoutes;
  final List<POI> filteredPois;

  // Filtros
  final String? selectedCategory;
  final double? selectedDistanceKm;
  final String? selectedSeason;
  final String query;

  MapLoaded({
    required this.center,
    required this.markers,
    required this.userLocation,
    required this.heading,
    required this.allRoutes,
    required this.filteredRoutes,
    required this.filteredPois,
    this.selectedCategory,
    this.selectedDistanceKm,
    this.selectedSeason,
    this.query = '',
  });

  MapLoaded copyWith({
    LatLng? center,
    List<LatLng>? markers,
    LatLng? userLocation,
    double? heading,
    List<MapRoute>? allRoutes,
    List<MapRoute>? filteredRoutes,
    List<POI>? filteredPois,
    Object? selectedCategory = _noChange,
    Object? selectedDistanceKm = _noChange,
    Object? selectedSeason = _noChange,
    Object? query = _noChange,
  }) {
    return MapLoaded(
      center: center ?? this.center,
      markers: markers ?? this.markers,
      userLocation: userLocation ?? this.userLocation,
      heading: heading ?? this.heading,
      allRoutes: allRoutes ?? this.allRoutes,
      filteredRoutes: filteredRoutes ?? this.filteredRoutes,
      filteredPois: filteredPois ?? this.filteredPois,
      selectedCategory: identical(selectedCategory, _noChange)
          ? this.selectedCategory
          : selectedCategory as String?,
      selectedDistanceKm: identical(selectedDistanceKm, _noChange)
          ? this.selectedDistanceKm
          : selectedDistanceKm as double?,
      selectedSeason: identical(selectedSeason, _noChange)
          ? this.selectedSeason
          : selectedSeason as String?,
      query: identical(query, _noChange)
          ? this.query
          : query as String,
    );
  }
}
/// 🚗 Estado de navegación activa
class MapNavigating extends MapState {
  final LatLng start;
  final LatLng destination;
  final List<LatLng> routePoints;
  final List<String> instructions;
  final double? heading;
  final LatLng? userLocation;

  MapNavigating({
    required this.start,
    required this.destination,
    required this.routePoints,
    required this.instructions,
    this.heading,
    this.userLocation,
  });
}
