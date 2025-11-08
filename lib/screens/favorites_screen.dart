import 'package:consultoria_chat_bot/blocs/favorites_cubit.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pantalla que muestra los POIs marcados como favoritos.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state.favorites.isEmpty) {
            return const Center(child: Text('Aún no tienes POIs favoritos.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: state.favorites.length,
            itemBuilder: (context, index) {
              final poi = state.favorites[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PoiScreen(poi)),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.surface, // mismo color que el fondo
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme
                            .colorScheme
                            .outlineVariant, // efecto “solo borde”
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // ==== Imagen a la izquierda (rectangular) ====
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                          child: SizedBox(
                            width: 100,
                            height: 90,
                            child: _PoiImage(url: poi.imagen),
                          ),
                        ),

                        // ==== Texto principal + categorías ====
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  poi.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (poi.categorias.isNotEmpty)
                                      ? poi.categorias.join(', ')
                                      : 'POI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ==== Flecha y botón de eliminar favorito ====
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            IconButton(
                              tooltip: 'Quitar de favoritos',
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.pink,
                              ),
                              onPressed: () {
                                context.read<FavoritesCubit>().toggleFavorite(
                                  poi,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget auxiliar para mostrar la imagen del POI
class _PoiImage extends StatelessWidget {
  final String url;
  const _PoiImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerLow;
    if (url.trim().isEmpty) {
      return Container(
        color: bg,
        alignment: Alignment.center,
        child: Icon(
          Icons.photo,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 32,
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: bg,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 32,
          ),
        );
      },
    );
  }
}