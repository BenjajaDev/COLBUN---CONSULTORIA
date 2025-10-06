import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:consultoria_chat_bot/services/firestore_service.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final FireStoreService _firebaseService;
  final Distance _distanceCalculator = const Distance();

  MapBloc(this._firebaseService) : super(MapInitial()) {
    on<AddMarker>(_onAddMarker);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHeading>(_onUpdateHeading);
    on<LoadRoute>(_onLoadRoute);
    on<ApplyFilters>(_onApplyFilters);

    _startTrackingLocation();
    _startTrackingHeading();
  }

  Future<void> _onLoadRoute(LoadRoute event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      final routes = await _firebaseService.fetchRoutes();
      final filteredRoutes = _filterRoutes(
        routes,
        query: '',
        category: null,
        distanceKm: null,
        season: null,
        userLocation: null,
      );
      final filteredPois = _collectFilteredPois(
        filteredRoutes,
        query: '',
        category: null,
      );

      emit(
        MapLoaded(
          center: const LatLng(-35.6960057, -71.4060907),
          markers: _buildMarkers(filteredPois),
          userLocation: null,
          heading: 0.0,
          allRoutes: routes,
          filteredRoutes: filteredRoutes,
          filteredPois: filteredPois,
        ),
      );
    } catch (e) {
      emit(MapError("Error al cargar la ruta: $e"));
    }
  }

  void _onAddMarker(AddMarker event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    final updatedMarkers = List<LatLng>.from(current.markers)
      ..add(event.position);
    emit(current.copyWith(markers: updatedMarkers));
  }

  void _onUpdateUserLocation(UpdateUserLocation event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    final updatedState = current.copyWith(
      userLocation: event.position,
      center: event.position,
    );
    emit(_recalculateFilters(updatedState));
  }

  void _onUpdateHeading(UpdateHeading event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    emit(current.copyWith(heading: event.heading));
  }

  void _onApplyFilters(ApplyFilters event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;

    final normalizedCategory = _normalizeFilterValue(event.category);
    final normalizedSeason = _normalizeFilterValue(event.season);
    final normalizedDistance =
        (event.distanceKm != null && event.distanceKm! > 0)
        ? event.distanceKm
        : null;
    final newQuery = event.query?.trim() ?? '';

    final updatedState = current.copyWith(
      selectedCategory: normalizedCategory,
      clearSelectedCategory: normalizedCategory == null,
      selectedDistanceKm: normalizedDistance,
      clearSelectedDistanceKm: normalizedDistance == null,
      selectedSeason: normalizedSeason,
      clearSelectedSeason: normalizedSeason == null,
      query: newQuery,
    );

    emit(_recalculateFilters(updatedState));
  }

  MapLoaded _recalculateFilters(MapLoaded base) {
    final filteredRoutes = _filterRoutes(
      base.allRoutes,
      query: base.query,
      category: base.selectedCategory,
      distanceKm: base.selectedDistanceKm,
      season: base.selectedSeason,
      userLocation: base.userLocation,
    );

    final filteredPois = _collectFilteredPois(
      filteredRoutes,
      query: base.query,
      category: base.selectedCategory,
    );

    return base.copyWith(
      filteredRoutes: filteredRoutes,
      filteredPois: filteredPois,
      markers: _buildMarkers(filteredPois),
    );
  }

  List<MapRoute> _filterRoutes(
    List<MapRoute> routes, {
    required String query,
    String? category,
    double? distanceKm,
    String? season,
    LatLng? userLocation,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = _normalizeFilterValue(category)?.toLowerCase();
    final normalizedSeason = _normalizeFilterValue(season)?.toLowerCase();
    final double? normalizedDistance = (distanceKm != null && distanceKm > 0)
        ? distanceKm
        : null;

    return routes
        .where((route) {
          final routeCategory = route.category?.toLowerCase();
          final routeSeason = route.season?.toLowerCase();

          final bool matchesCategory =
              normalizedCategory == null ||
              (routeCategory != null && routeCategory == normalizedCategory) ||
              route.pois.any(
                (poi) => poi.categorias
                    .map((c) => c.toLowerCase())
                    .contains(normalizedCategory),
              );
          if (!matchesCategory) return false;

          final bool matchesSeason =
              normalizedSeason == null ||
              (routeSeason != null && routeSeason == normalizedSeason);
          if (!matchesSeason) return false;

          final bool matchesDistance =
              normalizedDistance == null ||
              userLocation == null ||
              _routeDistanceFrom(route, userLocation) <= normalizedDistance;
          if (!matchesDistance) return false;

          if (normalizedQuery.isEmpty) {
            return true;
          }

          final bool routeNameMatchesQuery = route.name.toLowerCase().contains(
            normalizedQuery,
          );
          if (routeNameMatchesQuery) {
            return true;
          }

          final bool anyPoiMatchesQuery = route.pois.any(
            (poi) => poi.nombre.toLowerCase().contains(normalizedQuery),
          );
          return anyPoiMatchesQuery;
        })
        .map((route) {
          final normalizedCategory = _normalizeFilterValue(
            category,
          )?.toLowerCase();

          final filteredPois = route.pois.where((poi) {
            final matchesCategory =
                normalizedCategory == null ||
                poi.categorias
                    .map((c) => c.toLowerCase())
                    .contains(normalizedCategory);
            return matchesCategory;
          }).toList();

          return route.copyWith(pois: filteredPois);
        })
        .toList();
  }

  double _routeDistanceFrom(MapRoute route, LatLng userLocation) {
    final points = <LatLng>[];
    if (route.pois.isNotEmpty) {
      for (final poi in route.pois) {
        points.add(LatLng(poi.latitud, poi.longitud));
      }
    } else {
      points.add(LatLng(route.initialLatitude, route.initialLongitude));
      points.add(LatLng(route.finalLatitude, route.finalLongitude));
    }

    var minDistance = double.infinity;
    for (final point in points) {
      final distance = _distanceCalculator.as(
        LengthUnit.Kilometer,
        userLocation,
        point,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  List<POI> _collectFilteredPois(
    List<MapRoute> routes, {
    required String query,
    String? category,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = _normalizeFilterValue(category)?.toLowerCase();

    return routes.expand((route) {
      return route.pois.where((poi) {
        final matchesCategory =
            normalizedCategory == null ||
            poi.categorias
                .map((c) => c.toLowerCase())
                .contains(normalizedCategory);
        final matchesQuery =
            normalizedQuery.isEmpty ||
            poi.nombre.toLowerCase().contains(normalizedQuery);
        return matchesCategory && matchesQuery;
      });
    }).toList();
  }

  List<LatLng> _buildMarkers(List<POI> pois) {
    return pois.map((poi) => LatLng(poi.latitud, poi.longitud)).toList();
  }

  String? _normalizeFilterValue(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'todas') return null;
    return trimmed;
  }

  Future<void> _startTrackingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      add(UpdateUserLocation(LatLng(position.latitude, position.longitude)));
    });
  }

  void _startTrackingHeading() {
    FlutterCompass.events?.listen((event) {
      final heading = event.heading ?? 0.0;
      add(UpdateHeading(heading));
    });
  }
}
