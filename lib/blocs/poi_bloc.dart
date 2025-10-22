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

  /// Manejador del evento LoadPoi.
  ///
  /// Flujo principal:
  /// 1. Evita recargas si ya se está mostrando el mismo POI (previene parpadeo UI).
  /// 2. Emite estado de carga y consulta Firestore para categorías/actividades relacionadas.
  /// 3. Calcula listas de POIs recomendados y cercanos basadas en categoría y distancia.
  /// 4. Emite PoiLoaded con los datos preparados.
  void _onLoadPoi(LoadPoi event, Emitter<PoiState> emit) async {
    try {
      // 1) Si ya estamos mostrando este POI, ignorar para evitar UI blinking
      final currentState = state;
      if (currentState is PoiLoaded && currentState.current.id == event.current.id) {
        return;
      }

      // 2) Indicar que se está cargando
      emit(PoiLoading());

      final POI selected = event.current;
      // Todos los POIs excepto el seleccionado
      final List<POI> others = event.all
          .where((poi) => poi.id != selected.id)
          .toList();

      // Util para calcular distancias
      final Distance distance = const Distance();
      final LatLng selectedCoords = LatLng(selected.latitud, selected.longitud);

      // 3) Consultar metadatos (categorías y actividades) desde Firestore
      final List<Map<String, dynamic>> categorias = await FireStoreService().fetchCategory(selected.categorias);
      final List<Map<String, dynamic>> actividades = await FireStoreService().fetchActivity(selected.actividades);
      debugPrint('PoiBloc: fetched ${categorias.length} categories and ${actividades.length} activities for POI ${selected.id}');

      // 4) Construir lista de recomendados: priorizar coincidencia de categoría y luego distancia
      final Set<String> selectedCategories = Set<String>.from(selected.categorias);
      final List<POI> recommended = List<POI>.from(others);
      recommended.sort((a, b) {
        // Priorizar los que comparten categoría con el seleccionado
        final bool aMatches = a.categorias.any(selectedCategories.contains);
        final bool bMatches = b.categorias.any(selectedCategories.contains);
        if (aMatches != bMatches) {
          // Si uno coincide y el otro no, ordenar para poner el que coincide primero
          return bMatches ? 1 : -1;
        }
        // Si ambos coinciden (o ninguno), ordenar por distancia creciente
        final double da = distance(selectedCoords, LatLng(a.latitud, a.longitud));
        final double db = distance(selectedCoords, LatLng(b.latitud, b.longitud));
        return da.compareTo(db);
      });
      // Limitar la lista a 5 elementos para la UI
      final List<POI> limitedRecommended = recommended.take(5).toList();

      // 5) Calcular POIs cercanos al seleccionado (umbral configurable: aquí 10 km)
      final List<POI> nearby = <POI>[];
      final Map<String, double> distancesKm = <String, double>{};

      // Ordenar por distancia para ambos propósitos
      final List<POI> sortedByPoi = List<POI>.from(others);
      sortedByPoi.sort((a, b) {
        final double da = distance(selectedCoords, LatLng(a.latitud, a.longitud));
        final double db = distance(selectedCoords, LatLng(b.latitud, b.longitud));
        return da.compareTo(db);
      });

      for (final POI poi in sortedByPoi) {
        final double dMeters = distance(selectedCoords, LatLng(poi.latitud, poi.longitud));
        final double dKm = dMeters / 1000.0;
        distancesKm[poi.id] = dKm;

        // Agregar a 'nearby' si está por debajo del umbral (10 km aquí)
        if (dKm <= 10.0) {
          nearby.add(poi);
        }
      }
      // Limitar 'nearby' a los 5 primeros para evitar listas muy largas en la UI
      if (nearby.length > 5) {
        nearby.removeRange(5, nearby.length);
      }

      // 6) Emitir estado cargado con todas las estructuras necesarias para la UI
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
      // En caso de error, emitir estado de error genérico (podemos mejorar el mensaje más adelante)
      emit(PoiError('Error al cargar los datos'));
    }
  }
}
