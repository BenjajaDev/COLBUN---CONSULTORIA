import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Estado inmutable que almacena los POIs marcados como favoritos.
class FavoritesState {
  final List<POI> favorites;

  // Constructor con lista de favoritos inicial (vacía por defecto).
  const FavoritesState({this.favorites = const []});

  // Verifica si un POI con un determinado id ya está dentro de favoritos.
  bool contains(String id) {
    return favorites.any((poi) => poi.id == id);
  }

  // Retorna una copia del estado actual, reemplazando la lista de favoritos
  // si se entrega una nueva. Esto mantiene la inmutabilidad.
  FavoritesState copyWith({List<POI>? favorites}) {
    return FavoritesState(favorites: favorites ?? this.favorites);
  }
}

// Cubit encargado de manejar la lógica para añadir o quitar POIs de favoritos.
class FavoritesCubit extends Cubit<FavoritesState> {
  // Inicializa el estado con una lista vacía de favoritos.
  FavoritesCubit() : super(const FavoritesState());

  // Alterna el estado de favorito de un POI:
  //   - Si ya es favorito, lo elimina.
  //   - Si no lo es, lo agrega.
  void toggleFavorite(POI poi) {
    final isFavorite = state.contains(poi.id);

    if (isFavorite) {
      // Crea una nueva lista excluyendo el POI actual.
      final updated = state.favorites
          .where((item) => item.id != poi.id)
          .toList();

      // Emite un nuevo estado con la lista actualizada.
      emit(state.copyWith(favorites: updated));
    } else {
      // Crea una copia de la lista actual y añade el nuevo POI.
      final updated = List<POI>.from(state.favorites)..add(poi);

      // Emite un nuevo estado con la lista ampliada.
      emit(state.copyWith(favorites: updated));
    }
  }
}
