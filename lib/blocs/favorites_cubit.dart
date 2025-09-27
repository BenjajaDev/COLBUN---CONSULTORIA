import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  FavoritesCubit() : super(const FavoritesState());

  void toggleFavorite(POI poi) {
    final isFavorite = state.contains(poi.id);
    if (isFavorite) {
      final updated = state.favorites
          .where((item) => item.id != poi.id)
          .toList();
      emit(state.copyWith(favorites: updated));
    } else {
      final updated = List<POI>.from(state.favorites)..add(poi);
      emit(state.copyWith(favorites: updated));
    }
  }
}
