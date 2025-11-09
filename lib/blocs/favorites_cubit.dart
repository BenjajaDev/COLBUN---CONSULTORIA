import 'dart:convert';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/services/analytics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Estado inmutable que almacena los POIs marcados como favoritos.
class FavoritesState {
  final List<POI> favorites;

  const FavoritesState({this.favorites = const []});

  // Verifica si un POI ya está marcado como favorito.
  bool contains(String id) {
    return favorites.any((poi) => poi.id == id);
  }

  FavoritesState copyWith({List<POI>? favorites}) {
    return FavoritesState(favorites: favorites ?? this.favorites);
  }
}

// Cubit encargado de añadir o quitar POIs de la lista de favoritos.
class FavoritesCubit extends Cubit<FavoritesState> {
  static const String _prefsKey = 'favorites_pois_v1';

  FavoritesCubit() : super(const FavoritesState()) {
    _loadFavorites();
  }

  // Persist favorites whenever they change
  Future<void> _saveFavorites(List<POI> favorites) async {
    try {
      AnalyticsService.logEvent('favorites_updated', {'count': favorites.length});
      final prefs = await SharedPreferences.getInstance();
      final list = favorites.map(_poiToMap).toList();
      final jsonStr = jsonEncode(list);
      await prefs.setString(_prefsKey, jsonStr);
    } catch (_) {
      // Silently ignore persistence errors
    }
  }

  // Load favorites from local storage on startup
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr == null || jsonStr.isEmpty) return;
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map(_poiFromMap)
            .toList();
        emit(state.copyWith(favorites: loaded));
      }
    } catch (_) {
      // Ignore corrupt data and keep empty state
    }
  }

  void toggleFavorite(POI poi) {
    final isFavorite = state.contains(poi.id);
    if (isFavorite) {
      final updated = state.favorites
          .where((item) => item.id != poi.id)
          .toList();
      emit(state.copyWith(favorites: updated));
      // Analytics: quitar de favoritos
      AnalyticsService.logMarcarFavorito(
        'poi',
        poi.id,
        nombre: poi.nombre,
        accion: 'quitar',
      );
      _saveFavorites(updated);
    } else {
      final updated = List<POI>.from(state.favorites)..add(poi);
      emit(state.copyWith(favorites: updated));
      // Analytics: agregar a favoritos
      AnalyticsService.logMarcarFavorito(
        'poi',
        poi.id,
        nombre: poi.nombre,
        accion: 'agregar',
      );
      _saveFavorites(updated);
    }
  }

  // --- Serialization helpers (kept local to avoid changing the model) ---
  Map<String, dynamic> _poiToMap(POI p) => {
        'id': p.id,
        'nombre': p.nombre,
        'descripcion': p.descripcion,
        'imagen': p.imagen,
        'latitud': p.latitud,
        'longitud': p.longitud,
        'categorias': p.categorias,
        'actividades': p.actividades,
        'vistas360': p.vistas360,
      };

  POI _poiFromMap(Map<String, dynamic> m) => POI(
        id: (m['id'] ?? '').toString(),
        nombre: (m['nombre'] ?? '').toString(),
        descripcion: (m['descripcion'] as Map?)?.cast<String, dynamic>() ?? {},
        imagen: (m['imagen'] ?? '').toString(),
        latitud: (m['latitud'] as num?)?.toDouble() ?? 0.0,
        longitud: (m['longitud'] as num?)?.toDouble() ?? 0.0,
        categorias: (m['categorias'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
        actividades: (m['actividades'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
        vistas360: (m['vistas360'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}
