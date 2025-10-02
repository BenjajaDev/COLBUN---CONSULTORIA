import 'package:consultoria_chat_bot/blocs/favorites_cubit.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Pantalla que muestra los POIs marcados como favoritos.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'), // Título de la barra de la pantalla.
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          // Si no hay favoritos, muestra mensaje centrado.
          if (state.favorites.isEmpty) {
            return const Center(child: Text('Aun no tienes POIs favoritos.'));
          }

          // Lista con separadores que muestra los POIs favoritos.
          return ListView.separated(
            itemCount:
                state.favorites.length, // Número de elementos en la lista.
            separatorBuilder: (context, index) =>
                const Divider(height: 1), // Separador visual.
            itemBuilder: (context, index) {
              final poi = state.favorites[index]; // POI actual del índice.

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6), // Bordes redondeados.
                  child: Image.network(
                    poi.imagen, // Imagen del POI.
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // En caso de error al cargar imagen, muestra un icono predeterminado.
                      return Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.photo, color: Colors.grey),
                      );
                    },
                  ),
                ),
                title: Text(poi.nombre), // Nombre del POI.
                // Muestra categorías si existen, separadas por coma.
                subtitle: poi.categorias.isNotEmpty
                    ? Text(poi.categorias.join(', '))
                    : null,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.pink,
                  ), // Icono de favorito.
                  // Al pulsar alterna entre favorito/no favorito.
                  onPressed: () {
                    context.read<FavoritesCubit>().toggleFavorite(poi);
                  },
                ),
                // Al tocar la fila, navega a la pantalla de detalle del POI.
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PoiScreen(poi)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
