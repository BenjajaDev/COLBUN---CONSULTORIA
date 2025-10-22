import 'package:flutter/material.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Hoja inferior que muestra rutas y POIs disponibles.
// - Permite seleccionar una ruta para ver sus POIs.
// - Permite iniciar navegación hacia un POI (pasando languageCode actual).
// - Reposiciona el mapa según selección del usuario.
class AvailablePoisRoutesSheet extends StatelessWidget {
  // Estado actual del MapBloc (MapLoaded o derivado) con rutas/pois filtrados.
  final dynamic state;
  // Índice de la ruta seleccionada (o null si no hay selección).
  final int? selectedRouteIndex;
  // Callback al seleccionar una ruta desde la lista principal.
  final void Function(int) onRouteSelected;
  // Callback para limpiar la selección de ruta y volver a la vista general.
  final void Function() onClearSelectedRoute;
  // Mueve el mapa a un centro/zoom determinados.
  final void Function(LatLng, {double? zoom}) onMoveMap;
  // Establece el índice de ruta seleccionada (actualiza el estado en el parent).
  final void Function(int?) setSelectedRouteIndex;
  // Opacidad a usar para acentos (si corresponde a tu diseño).
  final double primaryColorOpacity;
  // Color primario para resaltar elementos (botones, íconos, selección).
  final Color primaryColor;
  // Controlador del mapa (para movimientos programáticos desde la hoja).
  final MapController mapController;
  // Controlador del scroll de la hoja (para sincronizar con DraggableScrollableSheet).
  final ScrollController scrollController;

  const AvailablePoisRoutesSheet({
    super.key,
    required this.state,
    required this.selectedRouteIndex,
    required this.onRouteSelected,
    required this.onClearSelectedRoute,
    required this.onMoveMap,
    required this.setSelectedRouteIndex,
    required this.primaryColorOpacity,
    required this.primaryColor,
    required this.mapController,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // ¿Hay texto de búsqueda activo?
    final hasSearch = state.query.trim().isNotEmpty;
    // Rutas filtradas según búsqueda/filtros desde MapBloc.
    final filteredRoutes = state.filteredRoutes;
    // Ruta seleccionada (si el índice actual es válido), sino null.
    final selectedRoute = (selectedRouteIndex != null &&
            selectedRouteIndex! >= 0 &&
            selectedRouteIndex! < filteredRoutes.length)
        ? filteredRoutes[selectedRouteIndex!]
        : null;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "manija" superior para indicar que la hoja es arrastrable
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Flecha para volver a la lista general cuando hay una ruta seleccionada
                if (selectedRoute != null)
                  GestureDetector(
                    onTap: onClearSelectedRoute,
                    child: const Icon(
                      Icons.arrow_back,
                      size: 22,
                    ),
                  ),
                if (selectedRoute != null) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // Título dinámico de la hoja: resultado, lista disponible o nombre de ruta
                    hasSearch
                        ? AppLocalizations.of(context)!.resultado_busqueda
                        : selectedRoute == null
                            ? AppLocalizations.of(context)!.rutas_disponibles
                            : selectedRoute.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: state.query.trim().isNotEmpty
                ? (state.filteredRoutes.isEmpty && state.filteredPois.isEmpty)
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.sin_resultado,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      )
          : ListView(
            controller: scrollController,
                        children: [
                          // Lista de rutas (resultado de búsqueda)
                          ...filteredRoutes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final route = entry.value;
                            return ListTile(
                              // Ícono transparente para alinear con otras filas
                              leading: const Icon(
                                Icons.alt_route,
                                color: Colors.transparent,
                              ),
                              title: Text(
                                '${AppLocalizations.of(context)!.ruta} ${route.name}',
                              ),
                              selected: selectedRouteIndex == index,
                              // Realce de selección usando color primario (puedes ajustar opacidad si lo prefieres)
                              selectedTileColor: primaryColor,
                              onTap: () {
                                // Centra el mapa en el punto medio de la ruta y selecciona la fila
                                final center = LatLng(
                                  (route.initialLatitude + route.finalLatitude) / 2,
                                  (route.initialLongitude + route.finalLongitude) / 2,
                                );
                                setSelectedRouteIndex(index);
                                onMoveMap(center, zoom: 14);
                              },
                              // Use theme-aware icon color
                              iconColor: primaryColor,
                              leadingAndTrailingTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            );
                          }),
                          // Lista de POIs (resultado de búsqueda)
                          ...state.filteredPois.map((poi) => ListTile(
                                leading: FilledButton.icon(
                                  onPressed: () {
                                    // Iniciar navegación hacia el POI, pasando el código de idioma actual de la app
                                    context.read<MapBloc>().add(
                                          RequestNavigation(
                                            LatLng(poi.latitud, poi.longitud),
                                            Localizations.localeOf(context).languageCode,
                                          ),
                                        );
                                  },
                                  // Usar texto localizado para el botón "Ir"
                                  label: Text(AppLocalizations.of(context)!.ir),
                                  icon: const Icon(Icons.navigation),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                title: Text(poi.nombre),
                                subtitle: poi.categorias.isNotEmpty
                                    ? Text(poi.categorias.first)
                                    : null,
                                onTap: () {
                                  // Mover mapa al POI sin iniciar navegación
                                  onMoveMap(
                                    LatLng(poi.latitud, poi.longitud),
                                    zoom: 16,
                                  );
                                },
                                trailing: GestureDetector(
                                  onTap: () {
                                    // Abrir ficha del POI
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PoiScreen(poi),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              )),
                        ],
                      )
                : selectedRoute == null
          ? ListView.builder(
            controller: scrollController,
                        itemCount: state.filteredRoutes.length,
                        itemBuilder: (context, index) {
                          final route = state.filteredRoutes[index];
                          return ListTile(
                            leading: Icon(
                              Icons.alt_route,
                              color: primaryColor,
                            ),
                            title: Text(
                              '${AppLocalizations.of(context)!.ruta} ${route.name}',
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 18,
                            ),
                            selected: selectedRouteIndex == index,
                            // Realce de selección para la ruta activa
                            selectedTileColor: primaryColor,
                            onTap: () {
                              // Centra el mapa en el punto medio de la ruta y actualiza selección
                              final center = LatLng(
                                (route.initialLatitude + route.finalLatitude) / 2,
                                (route.initialLongitude + route.finalLongitude) / 2,
                              );
                              setSelectedRouteIndex(index);
                              onMoveMap(center, zoom: 14);
                            },
                          );
                        },
                      )
                    : selectedRoute.pois.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.sin_resultado,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          )
            : ListView.builder(
              controller: scrollController,
                            itemCount: selectedRoute.pois.length,
                            itemBuilder: (context, index) {
                              final poi = selectedRoute.pois[index];
                              return ListTile(
                                leading: FilledButton.icon(
                                  onPressed: () {
                                    // Iniciar navegación hacia el POI de la ruta seleccionada
                                    context.read<MapBloc>().add(
                                          RequestNavigation(
                                            LatLng(poi.latitud, poi.longitud),
                                            Localizations.localeOf(context).languageCode,
                                          ),
                                        );
                                  },
                                  // Usar texto localizado para el botón "Ir"
                                  label: Text(AppLocalizations.of(context)!.ir),
                                  icon: const Icon(Icons.navigation),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                title: Text(poi.nombre),
                                // Tocar la fila solo mueve el mapa (no inicia navegación)
                                onTap: () {
                                  onMoveMap(
                                    LatLng(poi.latitud, poi.longitud),
                                    zoom: 16,
                                  );
                                },
                                trailing: GestureDetector(
                                  onTap: () {
                                    // Abrir ficha del POI
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PoiScreen(poi),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
