import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
  MapLoaded? _previousLoadedState;
  double? _originalRouteDistanceMeters;
  double? _instructionsTotalDurationSeconds;

  MapBloc(this._firebaseService) : super(MapInitial()) {
    on<AddMarker>(_onAddMarker);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHeading>(_onUpdateHeading);
    on<LoadRoute>(_onLoadRoute);
    on<ApplyFilters>(_onApplyFilters);
    on<SearchQueryUpdated>(_onSearchQueryUpdated);
    on<RequestNavigation>(_onRequestNavigation);
    on<CancelNavigation>(_onCancelNavigation);

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

  // ✅ Exploración normal (sin navegación)
  if (state is MapLoaded) {
    final current = state as MapLoaded;
    final updatedState = current.copyWith(
      userLocation: currentPos,
      center: currentPos,
    );
    emit(_recalculateFilters(updatedState));
    return;
  }

  // ✅ Navegación activa
  if (state is MapNavigating) {
    final current = state as MapNavigating;

    if (current.routePoints.isEmpty) return;

    final nextPoint = current.routePoints.first;
    final distanceToNext = _distanceCalculator.as(
      LengthUnit.Meter,
      currentPos,
      nextPoint,
    );

    // Build updated lists first (no early emits)
    List<LatLng> updatedRoute = current.routePoints;
    List<Map<String, dynamic>> updatedInstructions = current.instructions;

    // Trim polyline when near next vertex
    if (distanceToNext < 25 && updatedRoute.length > 1) {
      updatedRoute = updatedRoute.skip(1).toList();
      _currentRoutePoints = updatedRoute;
    }

    // Consume instruction when near its representative point
    if (updatedInstructions.isNotEmpty) {
      final firstIns = updatedInstructions.first;
      final insPoint = firstIns['point'] as LatLng?;
      if (insPoint != null) {
        final distToIns = _distanceCalculator.as(
          LengthUnit.Meter,
          currentPos,
          insPoint,
        );
        const instructionConsumeThreshold = 25.0; // meters
        // Decrease current instruction distance/duration proportionally
        final double origDist = (firstIns['originalDistance'] as num?)?.toDouble() ?? (firstIns['distance'] as num?)?.toDouble() ?? 0.0;
        final double origDur = (firstIns['originalDuration'] as num?)?.toDouble() ?? (firstIns['duration'] as num?)?.toDouble() ?? 0.0;
        final double travelled = (origDist - distToIns).clamp(0.0, origDist);
        // Avoid negative values, ensure not exceeding original
        final double remainingStepDist = (origDist - travelled).clamp(0.0, origDist);
        // Simple proportional time reduction
        final double remainingStepDur = origDist > 0 ? (origDur * (remainingStepDist / origDist)) : 0.0;
        // Update the current step in-place
        updatedInstructions[0] = {
          ...firstIns,
          'distance': remainingStepDist,
          'duration': remainingStepDur,
        };

        if (distToIns <= instructionConsumeThreshold) {
          updatedInstructions = updatedInstructions.skip(1).toList();
        }
      }
    }

    // Recompute bearing towards next remaining point (if any)
    final LatLng bearingTarget = updatedRoute.isNotEmpty ? updatedRoute.first : nextPoint;
    final bearing = _calculateBearing(currentPos, bearingTarget);

    // compute remaining distance along remaining route points
    double remainingDistance = 0.0;
    if (updatedRoute.isNotEmpty) {
      // from current position to first point
      remainingDistance += _distanceCalculator.as(
        LengthUnit.Meter,
        currentPos,
        updatedRoute.first,
      );
      // along the rest of the polyline
      for (var i = 0; i < updatedRoute.length - 1; i++) {
        remainingDistance += _distanceCalculator.as(
          LengthUnit.Meter,
          updatedRoute[i],
          updatedRoute[i + 1],
        );
      }
    }

    // remaining duration from instructions (sum durations of remaining instructions)
    double remainingDuration = 0.0;
    for (final ins in updatedInstructions) {
      remainingDuration += (ins['duration'] as num?)?.toDouble() ?? 0.0;
    }

    final eta = DateTime.now().add(Duration(seconds: remainingDuration.round()));

    emit(current.copyWith(
      routePoints: updatedRoute,
      instructions: updatedInstructions,
      userLocation: currentPos,
      bearing: bearing,
      navigationInfo: {
        'remainingDistance': remainingDistance,
        'remainingDuration': remainingDuration,
        'eta': eta.toIso8601String(),
        'originalDistance': _originalRouteDistanceMeters ?? 0.0,
        'originalDuration': _instructionsTotalDurationSeconds ?? 0.0,
      },
    ));

    // Verificar desviación de la ruta
    final isOffRoute = _checkDeviationFromRoute(
      currentPos,
      _currentRoutePoints ?? [],
    );

    if (isOffRoute && _shouldRecalculate() && _currentDestination != null) {
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
    if (state is! MapLoaded && state is! MapNavigating) return;

    // Determine context for starting point and heading
    LatLng start;
    double initialBearing;
    bool isReroute = false;
    MapLoaded? loadedSnapshotToRestore;

    if (state is MapLoaded) {
      final current = state as MapLoaded;
      // keep a snapshot of the last loaded state so we can restore it on cancel only on first start
      _previousLoadedState = current;

      start = current.userLocation ?? const LatLng(-35.6960057, -71.4060907);
      initialBearing = current.heading;
      loadedSnapshotToRestore = current;
      // show loading when starting from loaded state
      emit(MapLoading());
    } else {
      final nav = state as MapNavigating;
      // reroute from current nav position
      start = nav.userLocation ?? nav.start;
      initialBearing = nav.bearing ?? 0.0;
      isReroute = true;
      // do not emit MapLoading to avoid UI flicker during reroute
    }

    final dist = const Distance().as(
      LengthUnit.Meter,
      start,
      event.destination,
    );
    if (dist > 6000000) {
      emit(MapError("Tu ubicación actual está demasiado lejos del destino. "));
      // If starting from MapLoaded, restore previous snapshot; if rerouting, keep current nav state
      if (!isReroute) {
        final snap = loadedSnapshotToRestore ?? _previousLoadedState;
        if (snap != null) {
          emit(snap);
        }
      }
      return;
    }
    try {
      const apiKey =
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjljYTA0MTkzZjE2NTQ4ZDdhMjA3OTc1ZGE5NWNjMmE1IiwiaCI6Im11cm11cjY0In0=';

      // Detectar idioma del sistema

      final lang = 'es';

      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
      );

      final body = jsonEncode({
        "coordinates": [
          [start.longitude, start.latitude],
          [event.destination.longitude, event.destination.latitude],
        ],
        "language": lang,
        "instructions": true,
        "units": "m",
      });

      final response = await http.post(
        url,
        headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final features = (data['features'] as List?) ?? [];
        if (features.isEmpty) {
          emit(MapError("No se encontraron rutas disponibles"));
          return;
        }

        final geometry = features.first['geometry'];
        final props = features.first['properties'];

        // 🔹 Coordenadas directas
        final coords = (geometry['coordinates'] as List)
            .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
            .toList();

        // 🔹 Instrucciones
        final segments = (props['segments'] as List?) ?? [];
        final instructions = <Map<String, dynamic>>[];
        for (final segment in segments) {
          final steps = (segment['steps'] as List?);
          if (steps == null || steps.isEmpty) {
            emit(MapError("No se encontraron pasos en la ruta."));
            return;
          }
          for (final s in steps) {
            // try to resolve a representative LatLng for this step from way_points
            LatLng? stepPoint;
            try {
              final wp = s['way_points'] as List?;
              if (wp != null && wp.isNotEmpty) {
                final idx = (wp.last as num).toInt();
                if (idx >= 0 && idx < coords.length) {
                  stepPoint = coords[idx];
                }
              }
            } catch (_) {
              // ignore; leave stepPoint null
            }

            instructions.add(<String, dynamic>{
              'instruction': s['instruction'],
              'distance': s['distance'], // metros (will be updated live for the current step)
              'duration': s['duration'], // segundos (will be updated live for the current step)
              'originalDistance': s['distance'], // keep originals for recompute
              'originalDuration': s['duration'],
              'point': stepPoint,
            });
          }
          // 🔹 Cada paso contiene directamente 'instruction', 'distance', 'duration'
         
        }
        
       
        _currentRoutePoints = coords;
        _currentDestination = event.destination;

        // compute original route distance (meters)
        double routeDist = 0.0;
        for (var i = 0; i < coords.length - 1; i++) {
          routeDist += const Distance().as(
            LengthUnit.Meter,
            coords[i],
            coords[i + 1],
          );
        }
        _originalRouteDistanceMeters = routeDist;

        // total instructions duration seconds
        double totalDur = 0.0;
        for (final ins in instructions) {
          totalDur += (ins['duration'] as num?)?.toDouble() ?? 0.0;
        }
        _instructionsTotalDurationSeconds = totalDur;

  // supply an initial userLocation so UI markers can render immediately
  final LatLng initialUserLocation = start;

        emit(
          MapNavigating(
            start: start,
            destination: event.destination,
            routePoints: coords,
            instructions: instructions,
            userLocation: initialUserLocation,
            bearing: initialBearing,
            navigationInfo: {
              'remainingDistance': routeDist,
              'remainingDuration': totalDur,
              'eta': DateTime.now().add(Duration(seconds: totalDur.round())).toIso8601String(),
            },
          ),
        );
      } else {
      
        emit(
          MapError(
            'Error al obtener ruta: ${response.statusCode}\n${response.body}',
          ),
        );
      }
    } catch (e) {
      emit(MapError("Error al navegar: $e"));
    }
  }

  bool _checkDeviationFromRoute(LatLng currentPos, List<LatLng> routePoints) {
    // Use distance to the nearest segment instead of nearest vertex
    const deviationThreshold = 30.0; // meters (tighter than before)

    if (routePoints.isEmpty) return false;
    if (routePoints.length == 1) {
      final d = _distanceCalculator.as(LengthUnit.Meter, currentPos, routePoints.first);
      return d > deviationThreshold;
    }

    double minDistance = double.infinity;
    for (var i = 0; i < routePoints.length - 1; i++) {
      final a = routePoints[i];
      final b = routePoints[i + 1];
      final d = _distanceToSegmentMeters(currentPos, a, b);
      if (d < minDistance) minDistance = d;
      if (minDistance <= deviationThreshold) return false; // early accept
    }
    return minDistance > deviationThreshold;
  }

  bool _shouldRecalculate() {
    if (_lastRecalculation == null) return true;
    final diff = DateTime.now().difference(_lastRecalculation!).inSeconds;
    return diff > 8; // lower cooldown for faster reroutes
  }

  // =============================
  // 🔹 GEOMETRY HELPERS
  // =============================
  // Compute closest point on segment AB to point P (linear on lat/lon)
  LatLng _closestPointOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final vx = bx - ax;
    final vy = by - ay;
    final wx = px - ax;
    final wy = py - ay;

    final c1 = vx * wx + vy * wy;
    final c2 = vx * vx + vy * vy;
    double t = c2 > 0 ? (c1 / c2) : 0.0;
    if (t < 0) t = 0;
    if (t > 1) t = 1;

    final cx = ax + t * vx;
    final cy = ay + t * vy;
    return LatLng(cy, cx);
  }

  // Distance from point P to segment AB in meters
  double _distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final c = _closestPointOnSegment(p, a, b);
    return _distanceCalculator.as(LengthUnit.Meter, p, c);
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
        distanceFilter: 0,
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

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * (3.1415926535 / 180.0);
    final lon1 = from.longitude * (3.1415926535 / 180.0);
    final lat2 = to.latitude * (3.1415926535 / 180.0);
    final lon2 = to.longitude * (3.1415926535 / 180.0);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x);

    return (bearing * 180.0 / 3.1415926535 + 360.0) % 360.0;
  }

  FutureOr<void> _onCancelNavigation(CancelNavigation event, Emitter<MapState> emit) {
    // Clear internal navigation tracking
    _currentRoutePoints = null;
    _currentDestination = null;
    _lastRecalculation = null;

    if (_previousLoadedState != null) {
      emit(_previousLoadedState!);
      _previousLoadedState = null;
    } else {
      // Fallback: emit an empty MapLoaded if we don't have a snapshot
      emit(MapLoaded(
        center: const LatLng(-35.6960057, -71.4060907),
        markers: [],
        userLocation: null,
        heading: 0.0,
        allRoutes: [],
        filteredRoutes: [],
        filteredPois: [],
      ));
    }
  }
  
}

