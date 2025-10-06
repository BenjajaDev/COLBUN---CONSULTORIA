import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:latlong2/latlong.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final LatLng center;
  final List<LatLng> markers;
  final LatLng? userLocation;
  final double heading;
  final List<MapRoute> allRoutes;
  final List<MapRoute> filteredRoutes;
  final List<POI> filteredPois;
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
    String? selectedCategory,
    bool clearSelectedCategory = false,
    double? selectedDistanceKm,
    bool clearSelectedDistanceKm = false,
    String? selectedSeason,
    bool clearSelectedSeason = false,
    String? query,
  }) {
    return MapLoaded(
      center: center ?? this.center,
      markers: markers ?? this.markers,
      userLocation: userLocation ?? this.userLocation,
      heading: heading ?? this.heading,
      allRoutes: allRoutes ?? this.allRoutes,
      filteredRoutes: filteredRoutes ?? this.filteredRoutes,
      filteredPois: filteredPois ?? this.filteredPois,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedDistanceKm: clearSelectedDistanceKm
          ? null
          : (selectedDistanceKm ?? this.selectedDistanceKm),
      selectedSeason: clearSelectedSeason
          ? null
          : (selectedSeason ?? this.selectedSeason),
      query: query ?? this.query,
    );
  }
}

class MapError extends MapState {
  final String message;
  MapError(this.message);
}
