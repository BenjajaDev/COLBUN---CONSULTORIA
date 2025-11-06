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
        title: const Text('Favoritos'),
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          // Muestra un mensaje si todavia no se han marcado favoritos.
          if (state.favorites.isEmpty) {
            return const Center(
              child: Text('Aun no tienes POIs favoritos.'),
            );
          }

          // Lista reactiva con acceso rapido al detalle y opcion para remover.
          return ListView.separated(
            itemCount: state.favorites.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final poi = state.favorites[index];

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    poi.imagen,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    cacheWidth: 360,
                    cacheHeight: 360,
                    errorBuilder: (context, error, stackTrace) {
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
                title: Text(poi.nombre),
                subtitle: poi.categorias.isNotEmpty
                    ? Text(poi.categorias.join(', '))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.pink),
                  onPressed: () {
                    context.read<FavoritesCubit>().toggleFavorite(poi);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoiScreen(poi),
                    ),
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
