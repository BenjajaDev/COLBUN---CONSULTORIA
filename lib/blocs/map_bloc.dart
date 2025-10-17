import 'dart:convert';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:consultoria_chat_bot/services/firestore_service.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapBloc extends Bloc<MapEvent, MapState> {
  final FireStoreService _firebaseService;
  final Distance _distanceCalculator = const Distance();

  // Variables internas para navegación
  List<LatLng>? _currentRoutePoints;
  LatLng? _currentDestination;
  DateTime? _lastRecalculation;

  MapBloc(this._firebaseService) : super(MapInitial()) {
    on<AddMarker>(_onAddMarker);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHeading>(_onUpdateHeading);
    on<LoadRoute>(_onLoadRoute);
    on<ApplyFilters>(_onApplyFilters);
    on<SearchQueryUpdated>(_onSearchQueryUpdated);
    on<RequestNavigation>(_onRequestNavigation);
    on<CancelNavigation>((_, emit) => emit(MapInitial()));

    _startTrackingLocation();
    _startTrackingHeading();
  }

  // =============================
  // 🔹 CARGA INICIAL DE DATOS
  // =============================
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

  // =============================
  // 🔹 EVENTOS DE UI
  // =============================
  void _onAddMarker(AddMarker event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    final updatedMarkers = List<LatLng>.from(current.markers)
      ..add(event.position);
    emit(current.copyWith(markers: updatedMarkers));
  }

  void _onUpdateUserLocation(UpdateUserLocation event, Emitter<MapState> emit) {
    if (state is! MapLoaded && state is! MapNavigating) return;

    final currentPos = event.position;
    final current = state;

    // Actualiza la posición actual en MapLoaded
    if (current is MapLoaded) {
      final updatedState = current.copyWith(
        userLocation: currentPos,
        center: currentPos,
      );
      emit(_recalculateFilters(updatedState));
    }

    // 🔹 Lógica de detección de desviación si hay ruta activa
    if (_currentRoutePoints != null && _currentDestination != null) {
      final isOffRoute = _checkDeviationFromRoute(
        currentPos,
        _currentRoutePoints!,
      );
      if (isOffRoute && _shouldRecalculate()) {
        _lastRecalculation = DateTime.now();
        add(RequestNavigation(_currentDestination!));
      }
    }
  }

  void _onUpdateHeading(UpdateHeading event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    emit(current.copyWith(heading: event.heading));
  }

  // =============================
  // 🔹 BÚSQUEDA Y FILTRO CENTRALIZADO
  // =============================

  void _onSearchQueryUpdated(SearchQueryUpdated event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;

    final updatedState = current.copyWith(query: event.query.trim());
    emit(_recalculateFilters(updatedState));
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
      selectedDistanceKm: normalizedDistance,
      selectedSeason: normalizedSeason,
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

  // =============================
  // 🔹 FILTRO Y CÁLCULOS AUXILIARES
  // =============================

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

    // 🟢 Si no hay ningún filtro activo, devolvemos todo
    if (normalizedQuery.isEmpty &&
        normalizedCategory == null &&
        normalizedSeason == null &&
        normalizedDistance == null) {
      return routes; // 🟢 Mostrar todo sin filtrar
    }

    return routes
        .where((route) {
          final routeCategory = route.category?.toLowerCase();
          final routeSeason = route.season?.toLowerCase();

          // Categoría
          final bool matchesCategory =
              normalizedCategory == null ||
              (routeCategory != null && routeCategory == normalizedCategory) ||
              route.pois.any(
                (poi) => poi.categorias
                    .map((c) => c.toLowerCase())
                    .contains(normalizedCategory),
              );
          if (!matchesCategory) return false;

          // Temporada
          final bool matchesSeason =
              normalizedSeason == null ||
              (routeSeason != null && routeSeason == normalizedSeason);
          if (!matchesSeason) return false;

          // Distancia
          final bool matchesDistance =
              normalizedDistance == null ||
              userLocation == null ||
              _routeDistanceFrom(route, userLocation) <= normalizedDistance;
          if (!matchesDistance) return false;

          // Búsqueda por nombre o punto
          if (normalizedQuery.isEmpty) return true;

          final bool routeNameMatchesQuery = route.name.toLowerCase().contains(
            normalizedQuery,
          );
          if (routeNameMatchesQuery) return true;

          final bool anyPoiMatchesQuery = route.pois.any(
            (poi) => poi.nombre.toLowerCase().contains(normalizedQuery),
          );
          return anyPoiMatchesQuery;
        })
        .map((route) {
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

  // =============================
  // 🔹 NAVEGACIÓN / ROUTING
  // =============================
  Future<void> _onRequestNavigation(
    RequestNavigation event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;

    var start = current.userLocation;
    if (start == null) {
      //emit(MapError("Ubicación del usuario no disponible"));
      //return;
      start = LatLng(-35.6960057, -71.4060907); // Ubicación por defecto
    }

    emit(MapLoading());
    try {
      const apiKey =
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjljYTA0MTkzZjE2NTQ4ZDdhMjA3OTc1ZGE5NWNjMmE1IiwiaCI6Im11cm11cjY0In0=';
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car'
        '?api_key=$apiKey'
        '&start=${start.longitude},${start.latitude}'
        '&end=${event.destination.longitude},${event.destination.latitude}'
        '&instructions=true',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        final routePoints = coords
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();

        final steps = data['features'][0]['properties']['segments'][0]['steps'];
        final instructions = steps
            .map<String>((s) => s['instruction'].toString())
            .toList();

        _currentRoutePoints = routePoints;
        _currentDestination = event.destination;

        emit(
          MapNavigating(
            start: start,
            destination: event.destination,
            routePoints: routePoints,
            instructions: instructions,
          ),
        );
      } else {
        emit(MapError('Error al obtener ruta: ${response.statusCode}'));
      }
    } catch (e) {
      emit(MapError("Error al navegar: $e"));
    }
  }

  bool _checkDeviationFromRoute(LatLng currentPos, List<LatLng> routePoints) {
    const deviationThreshold = 50.0; // metros
    double minDistance = double.infinity;

    for (final point in routePoints) {
      final distance = _distanceCalculator.as(
        LengthUnit.Meter,
        currentPos,
        point,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance > deviationThreshold;
  }

  bool _shouldRecalculate() {
    if (_lastRecalculation == null) return true;
    final diff = DateTime.now().difference(_lastRecalculation!).inSeconds;
    return diff > 20;
  }

  // =============================
  // 🔹 TRACKING UBICACIÓN Y HEADING
  // =============================
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
