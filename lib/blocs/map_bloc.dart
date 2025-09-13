import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../data/map_repository.dart';   
import '../data/poi.dart';              

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository repo;

  
  MapBloc({MapRepository? repo})
      : repo = repo ?? MapRepository(),
        super(MapInitial(center: const LatLng(-35.4269, -71.6656))) {
    on<AddMarker>(_onAddMarker);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHeading>(_onUpdateHeading);
    on<LoadPois>(_onLoadPois);

    _startTrackingLocation();
    _startTrackingHeading();
  }



  void _onAddMarker(AddMarker event, Emitter<MapState> emit) {
    final current = state as MapInitial;
    final updatedMarkers = List<LatLng>.from(current.markers)..add(event.position);
    emit(MapInitial(
      center: current.center,
      markers: updatedMarkers,
      userLocation: current.userLocation,
      heading: current.heading,
    ));
  }

  void _onUpdateUserLocation(UpdateUserLocation event, Emitter<MapState> emit) {
    final current = state as MapInitial;
    emit(MapInitial(
      center: event.position,
      markers: current.markers,
      userLocation: event.position,
      heading: current.heading,
    ));
  }

  void _onUpdateHeading(UpdateHeading event, Emitter<MapState> emit) {
    final current = state as MapInitial;
    emit(MapInitial(
      center: current.center,
      markers: current.markers,
      userLocation: current.userLocation,
      heading: event.heading,
    ));
  }

  
  Future<void> _onLoadPois(LoadPois event, Emitter<MapState> emit) async {
    final current = state as MapInitial;

   
    final List<Poi> pois = await repo.fetchPoisByRoute(event.routeId);

   
    final markers = pois.map((p) => p.location).toList();

    final newCenter = markers.isNotEmpty ? markers.first : current.center;

  
    emit(MapInitial(
      center: newCenter,
      markers: markers,
      userLocation: current.userLocation,
      heading: current.heading,
    ));
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
