import 'package:consultoria_chat_bot/services/firestore_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final FireStoreService _firebaseService;

  MapBloc(this._firebaseService) : super(MapInitial()) {
    on<AddMarker>(_onAddMarker);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHeading>(_onUpdateHeading);
    on<LoadRoute>(_onLoadRoute);
   
    
    _startTrackingLocation();
    _startTrackingHeading();
  }

  

  Future<void> _onLoadRoute(
      LoadRoute event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      final routes = await _firebaseService.fetchRoutes();
      final poiMarkers = routes
    .expand((route) => route.pois) // toma todos los POIs de todas las rutas
    .map((poi) => LatLng(poi.latitud, poi.longitud))
    .toList();

      emit(MapLoaded(
        center: const LatLng(-35.6960057, -71.4060907), // Default
        markers: poiMarkers,
        userLocation: null,
        heading: 0.0,
        route: routes,
      ));
    } catch (e) {
      emit(MapError("Error al cargar la ruta: $e"));
    }
  }

  void _onAddMarker(AddMarker event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return; // ✅ Ignorar si no está listo
    final current = state as MapLoaded;

    final updatedMarkers = List<LatLng>.from(current.markers)
      ..add(event.position);

    emit(current.copyWith(markers: updatedMarkers));
  }

  void _onUpdateUserLocation(
      UpdateUserLocation event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return; // ✅ Ignorar si no está listo
    final current = state as MapLoaded;

    emit(current.copyWith(
      userLocation: event.position,
      center: event.position,
    ));
  }

  void _onUpdateHeading(UpdateHeading event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return; // ✅ Ignorar si no está listo
    final current = state as MapLoaded;

    emit(current.copyWith(heading: event.heading));
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
      add(UpdateUserLocation(
          LatLng(position.latitude, position.longitude)));
    });
  }

  void _startTrackingHeading() {
    FlutterCompass.events?.listen((event) {
      final heading = event.heading ?? 0.0;
      add(UpdateHeading(heading));
    });
  }
 
}
