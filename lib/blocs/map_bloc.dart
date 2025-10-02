import 'package:consultoria_chat_bot/services/firestore_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';

// Bloc que maneja eventos y estados relacionados con el mapa.
class MapBloc extends Bloc<MapEvent, MapState> {
  final FireStoreService _firebaseService;

  // Constructor que inicializa el estado inicial y registra los handlers de eventos.
  MapBloc(this._firebaseService) : super(MapInitial()) {
    on<AddMarker>(_onAddMarker);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHeading>(_onUpdateHeading);
    on<LoadRoute>(_onLoadRoute);

    // Inicia el seguimiento continuo de la ubicación y de la brújula.
    _startTrackingLocation();
    _startTrackingHeading();
  }

  // Maneja evento para cargar rutas desde Firestore, emite estados de carga y errores.
  Future<void> _onLoadRoute(LoadRoute event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      // Obtiene las rutas desde el servicio Firebase.
      final routes = await _firebaseService.fetchRoutes();

      // Extrae los POIs de todas las rutas y los convierte en marcadores LatLng.
      final poiMarkers = routes
          .expand((route) => route.pois)
          .map((poi) => LatLng(poi.latitud, poi.longitud))
          .toList();

      // Emite el estado cargado con el centro del mapa por defecto y los marcadores.
      emit(
        MapLoaded(
          center: const LatLng(-35.6960057, -71.4060907), // Centro default
          markers: poiMarkers,
          userLocation: null,
          heading: 0.0,
          route: routes,
        ),
      );
    } catch (e) {
      // En caso de error emite estado de error con mensaje.
      emit(MapError("Error al cargar la ruta: $e"));
    }
  }

  // Añade un marcador nuevo a la lista existente solo si el mapa está cargado.
  void _onAddMarker(AddMarker event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return; // Ignorar si no está listo
    final current = state as MapLoaded;

    // Copia la lista actual y añade la nueva posición.
    final updatedMarkers = List<LatLng>.from(current.markers)
      ..add(event.position);

    // Emite el estado actualizado con los marcadores agregados.
    emit(current.copyWith(markers: updatedMarkers));
  }

  // Actualiza la ubicación del usuario en el estado si el mapa está cargado.
  void _onUpdateUserLocation(UpdateUserLocation event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return; // Ignorar si no está listo
    final current = state as MapLoaded;

    // Actualiza ubicación y centro del mapa.
    emit(
      current.copyWith(userLocation: event.position, center: event.position),
    );
  }

  // Actualiza la orientación o heading según evento si el mapa está cargado.
  void _onUpdateHeading(UpdateHeading event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return; // Ignorar si no está listo
    final current = state as MapLoaded;

    // Emite el estado actualizado con la nueva orientación.
    emit(current.copyWith(heading: event.heading));
  }

  // Configura el rastreo continuo de la ubicación del usuario con permisos y filtros.
  Future<void> _startTrackingLocation() async {
    // Verifica que el servicio de ubicación esté activo.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Gestiona permisos de ubicación, solicitándolos si están denegados.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Escucha el stream de posiciones con alta precisión y filtro de distancia.
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      // Cada nueva posición genera evento para actualizar ubicación en el mapa.
      add(UpdateUserLocation(LatLng(position.latitude, position.longitude)));
    });
  }

  // Inicia el rastreo continuo de la orientación del dispositivo usando la brújula.
  void _startTrackingHeading() {
    FlutterCompass.events?.listen((event) {
      final heading = event.heading ?? 0.0;
      // Cada cambio en heading genera evento de actualización.
      add(UpdateHeading(heading));
    });
  }
}
