import 'package:consultoria_chat_bot/events/poi_event.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/services/firestore_service.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class PoiBloc extends Bloc<PoiEvent, PoiState> {
  PoiBloc() : super(PoiInitial()) {
    on<LoadPoi>(_onLoadPoi);
  }

  void _onLoadPoi(LoadPoi event, Emitter<PoiState> emit) async {
    try {
      // If we're already showing this POI, ignore duplicate requests to avoid UI blinking
      final currentState = state;
      if (currentState is PoiLoaded && currentState.current.id == event.current.id) {
        return;
      }

      emit(PoiLoading());

      final POI selected = event.current;
      final List<POI> others = event.all
          .where((poi) => poi.id != selected.id)
          .toList();
      final Distance distance = const Distance();
      final LatLng selectedCoords = LatLng(selected.latitud, selected.longitud);
      final List<Map<String, dynamic>> categorias = await FireStoreService().fetchCategory(selected.categorias);
      final List<Map<String, dynamic>> actividades = await FireStoreService().fetchActivity(selected.actividades);
      debugPrint('PoiBloc: fetched ${categorias.length} categories and ${actividades.length} activities for POI ${selected.id}');
      //Ajuste de recomendados priorizando categoria y distancia
      final Set<String> selectedCategories = Set<String>.from(
        selected.categorias,
      );
      final List<POI> recommended = List<POI>.from(others);
      recommended.sort((a, b) {
        final bool aMatches = a.categorias.any(selectedCategories.contains);
        final bool bMatches = b.categorias.any(selectedCategories.contains);
        if (aMatches != bMatches) {
          return bMatches ? 1 : -1;
        }
        final double da = distance(
          selectedCoords,
          LatLng(a.latitud, a.longitud),
        );
        final double db = distance(
          selectedCoords,
          LatLng(b.latitud, b.longitud),
        );
        return da.compareTo(db);
      });
      final List<POI> limitedRecommended = recommended.take(5).toList();

      //Cercanos al POI seleccionado (≤ 1 km)
      final List<POI> nearby = <POI>[];
      final Map<String, double> distancesKm = <String, double>{};

      final List<POI> sortedByPoi = List<POI>.from(others);
      sortedByPoi.sort((a, b) {
        final double da = distance(
          selectedCoords,
          LatLng(a.latitud, a.longitud),
        );
        final double db = distance(
          selectedCoords,
          LatLng(b.latitud, b.longitud),
        );
        return da.compareTo(db);
      });

      for (final POI poi in sortedByPoi) {
        final double dMeters = distance(
          selectedCoords,
          LatLng(poi.latitud, poi.longitud),
        );
        final double dKm = dMeters / 1000.0;
        distancesKm[poi.id] = dKm;

        if (dKm <= 10.0) {
          nearby.add(poi);
        }
      }
      if (nearby.length > 5) {
        nearby.removeRange(5, nearby.length);
      }
      
      emit(
        PoiLoaded(
          current: selected,
          recommended: limitedRecommended,
          nearby: nearby,
          distancesKm: distancesKm,
          categorias: categorias,
          actividades: actividades,
        ),
      );
    } catch (e) {
      emit(PoiError('Error al cargar los datos'));
    }
  }
}
