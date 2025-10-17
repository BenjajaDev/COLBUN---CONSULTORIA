import 'package:flutter/material.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AvailablePoisRoutesSheet extends StatelessWidget {
  final dynamic state;
  final int? selectedRouteIndex;
  final void Function(int) onRouteSelected;
  final void Function() onClearSelectedRoute;
  final void Function(LatLng, {double? zoom}) onMoveMap;
  final void Function(int?) setSelectedRouteIndex;
  final double primaryColorOpacity;
  final Color primaryColor;
  final MapController mapController;
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
    final hasSearch = state.query.trim().isNotEmpty;
    final filteredRoutes = state.filteredRoutes;
    final selectedRoute = (selectedRouteIndex != null &&
            selectedRouteIndex! >= 0 &&
            selectedRouteIndex! < filteredRoutes.length)
        ? filteredRoutes[selectedRouteIndex!]
        : null;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
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
                    hasSearch
                        ? AppLocalizations.of(context)!.resultado_busqueda
                        : selectedRoute == null
                            ? AppLocalizations.of(context)!.rutas_disponibles
                            : selectedRoute.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (selectedRoute != null)
                  TextButton.icon(
                    onPressed: onClearSelectedRoute,
                    icon: const Icon(
                      Icons.list,
                      size: 18,
                      color: Color(0xFF4D67AE),
                    ),
                    label: const Text(
                      'Ver rutas',
                      style: TextStyle(
                        color: Color(0xFF4D67AE),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      )
          : ListView(
            controller: scrollController,
                        children: [
                          ...filteredRoutes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final route = entry.value;
                            return ListTile(
                              leading: const Icon(
                                Icons.alt_route,
                                color: Color(0xFF4D67AE),
                              ),
                              title: Text(
                                '${AppLocalizations.of(context)!.ruta} ${route.name}',
                              ),
                              selected: selectedRouteIndex == index,
                              selectedTileColor:
                                  primaryColor.withOpacity(primaryColorOpacity),
                              onTap: () {
                                final center = LatLng(
                                  (route.initialLatitude + route.finalLatitude) / 2,
                                  (route.initialLongitude + route.finalLongitude) / 2,
                                );
                                setSelectedRouteIndex(index);
                                onMoveMap(center, zoom: 14);
                              },
                            );
                          }),
                          ...state.filteredPois.map((poi) => ListTile(
                                leading: FilledButton.icon(
                                  onPressed: () {
                                    context.read<MapBloc>().add(
                                          RequestNavigation(
                                            LatLng(poi.latitud, poi.longitud),
                                          ),
                                        );
                                  },
                                  label: const Text('Ir'),
                                  icon: const Icon(Icons.navigation),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                title: Text(poi.nombre),
                                subtitle: poi.categorias.isNotEmpty
                                    ? Text(poi.categorias.first)
                                    : null,
                                onTap: () {
                                  onMoveMap(
                                    LatLng(poi.latitud, poi.longitud),
                                    zoom: 16,
                                  );
                                },
                                trailing: GestureDetector(
                                  onTap: () {
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
                            leading: const Icon(
                              Icons.alt_route,
                              color: Color(0xFF4D67AE),
                            ),
                            title: Text(
                              '${AppLocalizations.of(context)!.ruta} ${route.name}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 18,
                            ),
                            selected: selectedRouteIndex == index,
                            selectedTileColor:
                                primaryColor.withOpacity(primaryColorOpacity),
                            onTap: () {
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
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
                                    context.read<MapBloc>().add(
                                          RequestNavigation(
                                            LatLng(poi.latitud, poi.longitud),
                                          ),
                                        );
                                  },
                                  label: const Text('Ir'),
                                  icon: const Icon(Icons.navigation),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                title: Text(poi.nombre),
                                subtitle: poi.categorias.isNotEmpty
                                    ? Text(poi.categorias.first)
                                    : null,
                                onTap: () {
                                  onMoveMap(
                                    LatLng(poi.latitud, poi.longitud),
                                    zoom: 16,
                                  );
                                },
                                trailing: GestureDetector(
                                  onTap: () {
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
