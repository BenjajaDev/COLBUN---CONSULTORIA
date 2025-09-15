import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:consultoria_chat_bot/data/routes_repository.dart';
import 'dart:async';
import 'package:consultoria_chat_bot/models/route360.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final RoutesRepository repo;
  StreamSubscription<List<Route360>>? _routesSub;

  MapBloc({required this.repo})
      : super(MapInitial(center: const LatLng(-33.4489, -70.6693))) {
    on<SubscribeRoutes>(_onSubscribeRoutes);
    on<LoadRoutes>(_onLoadRoutes);
    on<RoutesUpdated>(_onRoutesUpdated);
    on<SelectRoute>(_onSelectRoute);
    on<AddMarker>(_onAddMarker);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHeading>(_onUpdateHeading);
    on<DeselectRoute>((event, emit) {
      final cur = state as MapInitial;
      emit(cur.copyWith(selectedRouteId: null));
    });


    add(LoadRoutes()); 
    add(SubscribeRoutes());
  }

  void _onSubscribeRoutes(SubscribeRoutes event, Emitter<MapState> emit) {
    _routesSub?.cancel();
    _routesSub = repo.streamRoutes().listen(
      (routes) {
        add(RoutesUpdated(routes));
      },
      onError: (e) => emit(MapFailure(e.toString())),
    );
  }

  void _onRoutesUpdated(RoutesUpdated event, Emitter<MapState> emit) {
    final cur = state is MapInitial
        ? state as MapInitial
        : MapInitial(center: const LatLng(-35.78, -71.33));
    emit(cur.copyWith(
      routes: event.routes,
      selectedRouteId: cur.selectedRouteId,
    ));
  }


  Future<void> _onLoadRoutes(
      LoadRoutes event, Emitter<MapState> emit) async {
    try {
      final routes = await repo.fetchRoutes();
      add(RoutesUpdated(routes));
    } catch (e) {
      emit(MapFailure(e.toString()));
    }
  }

  void _onSelectRoute(SelectRoute event, Emitter<MapState> emit) {
    final cur = state as MapInitial;
    emit(cur.copyWith(selectedRouteId: event.routeId));
  }

  void _onAddMarker(AddMarker event, Emitter<MapState> emit) {
    final cur = state as MapInitial;
    final updated = List<LatLng>.from(cur.markers)..add(event.position);
    emit(cur.copyWith(markers: updated));
  }

  void _onUpdateUserLocation(
      UpdateUserLocation event, Emitter<MapState> emit) {
    final cur = state as MapInitial;
    emit(cur.copyWith(userLocation: event.position));
  }

  void _onUpdateHeading(UpdateHeading event, Emitter<MapState> emit) {
    final cur = state as MapInitial;
    emit(cur.copyWith(heading: event.heading));
  }

  @override
  Future<void> close() {
    _routesSub?.cancel(); 
    return super.close();
  }
}