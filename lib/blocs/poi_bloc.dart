import 'package:consultoria_chat_bot/events/poi_event.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

class PoiBloc extends Bloc<PoiEvent, PoiState> {
  PoiBloc() : super(PoiInitial()) {
    on<LoadPoi>(_onLoadPoi);
  }

  void _onLoadPoi(LoadPoi event, Emitter<PoiState> emit) async {
    try {
      emit(PoiLoading());

      final POI selected = event.current;
      final List<POI> others =
          event.all.where((poi) => poi.id != selected.id).toList();
      final Distance distance = const Distance();
      final LatLng selectedCoords =
          LatLng(selected.latitud, selected.longitud);

      //Ajuste de recomendados priorizando categoria y distancia
      final Set<String> selectedCategories =
          Set<String>.from(selected.categorias);
      final List<POI> recommended = List<POI>.from(others);
      recommended.sort((a, b) {
        final bool aMatches =
            a.categorias.any(selectedCategories.contains);
        final bool bMatches =
            b.categorias.any(selectedCategories.contains);
        if (aMatches != bMatches) {
          return bMatches ? 1 : -1;
        }
        final double da =
            distance(selectedCoords, LatLng(a.latitud, a.longitud));
        final double db =
            distance(selectedCoords, LatLng(b.latitud, b.longitud));
        return da.compareTo(db);
      });
      final List<POI> limitedRecommended = recommended.take(5).toList();

      //Calculo de cercanos con distancias al usuario
      final List<POI> nearby = <POI>[];
      final Map<String, double> distancesKm = <String, double>{};
      if (event.userLocation != null) {
        final LatLng user = event.userLocation!;
        final List<POI> sortedByUser = List<POI>.from(others);
        sortedByUser.sort((a, b) {
          final double da = distance(user, LatLng(a.latitud, a.longitud));
          final double db = distance(user, LatLng(b.latitud, b.longitud));
          return da.compareTo(db);
        });

        for (final POI poi in sortedByUser) {
          final double dMeters =
              distance(user, LatLng(poi.latitud, poi.longitud));
          distancesKm[poi.id] = dMeters / 1000.0;
        }

        nearby.addAll(sortedByUser.take(5));
      }

  
      emit(
        PoiLoaded(
          current: selected,
          recommended: limitedRecommended,
          nearby: nearby,
          distancesKm: distancesKm,
        ),
      );
    } catch (e) {
      emit(PoiError('Error al cargar los datos'));
    }
  }
}
