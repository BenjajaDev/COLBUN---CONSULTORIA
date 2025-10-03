import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:consultoria_chat_bot/screens/favorites_screen.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Página principal que muestra el mapa, lista de rutas y POIs, con búsqueda y selección.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final String apiKey = 'vuobOOmhVcspXRuOBRRs'; // API Key para capas de mapa.
  final MapController mapController =
      MapController(); // Controlador del mapa para centrar y mover.
  final TextEditingController searchController =
      TextEditingController(); // Controlador del campo búsqueda.
  int? selectedRouteIndex; // Índice de ruta seleccionada o null si ninguna.
  final double _initialSheetChildSize =
      0.25; // Tamaño inicial del panel inferior (draggable sheet).
  double _dragScrollSheetExtent =
      0; // Proporción actual del panel inferior desplegado.
  double _widgetHeight = 0; // Altura total para cálculo del FAB.
  double _fabPosition =
      0; // Posición vertical del botón flotante para centrar ubicación.
  final double _fabPositionPadding = 10; // Padding para el botón flotante.

  String searchQuery = ""; // Cadena actual para filtrar rutas y POIs.

  @override
  void initState() {
    // Al iniciar el widget, se dispara evento para cargar las rutas.
    BlocProvider.of<MapBloc>(context).add(LoadRoute());
    super.initState();

    // Después de construir se calcula la posición inicial del FAB en función del tamaño.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _fabPosition = _initialSheetChildSize * context.size!.height;
      });
    });
  }

  @override
  void dispose() {
    // Liberar recursos controladores para evitar fugas.
    mapController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Escucha cambios del estado MapBloc para construir la UI reactiva.
        child: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            if (state is MapLoaded) {
              // Extrae todos los POIs de todas las rutas para búsquedas y listado.
              final allPois = state.route
                  .expand((route) => route.pois)
                  .toList();

              // Filtra rutas según búsqueda y si no hay ruta seleccionada.
              final filteredRoutes =
                  (searchQuery.isNotEmpty && selectedRouteIndex == null)
                  ? state.route
                        .where(
                          (r) => r.name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          ),
                        )
                        .toList()
                  : (selectedRouteIndex == null ? state.route : []);

              // Filtra POIs según búsqueda y si hay una ruta seleccionada o no.
              final filteredPois = selectedRouteIndex != null
                  ? state.route[selectedRouteIndex!].pois
                        .where(
                          (p) => p.nombre.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          ),
                        )
                        .toList()
                  : (searchQuery.isEmpty
                        ? allPois
                        : allPois
                              .where(
                                (p) => p.nombre.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ),
                              )
                              .toList());

              return Stack(
                children: [
                  // Mapa principal con tiles y marcadores.
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: state.center,
                      initialZoom: 15,
                    ),
                    children: [
                      // Capa base de mapas con MapTiler.
                      TileLayer(
                        urlTemplate:
                            'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$apiKey',
                        userAgentPackageName: 'com.example.app',
                      ),
                      // Marcadores para POIs filtrados.
                      MarkerLayer(
                        markers: [
                          ...filteredPois.map(
                            (marker) => Marker(
                              point: LatLng(marker.latitud, marker.longitud),
                              width: 80,
                              height: 60,
                              child: GestureDetector(
                                onTap: () {
                                  // Al tocar marcador, navega a detalle del POI.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PoiScreen(marker),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                    Text(
                                      marker.nombre,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Marcador para ubicación del usuario con orientación.
                          if (state.userLocation != null)
                            Marker(
                              point: state.userLocation!,
                              child: Transform.rotate(
                                angle: state.heading * (3.1415926535 / 180),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4D67AE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Capa de polígonos para las rutas dibujadas en el mapa.
                      PolylineLayer(
                        polylines: state.route.map((route) {
                          return Polyline(
                            points: [
                              LatLng(
                                route.initialLatitude,
                                route.initialLongitude,
                              ),
                              LatLng(route.finalLatitude, route.finalLongitude),
                            ],
                            strokeWidth: 4.0,
                            color: Colors.red,
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Botón flotante para centrar el mapa en la ubicación del usuario.
                  Positioned(
                    bottom: _fabPosition + _fabPositionPadding,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF4D67AE),
                      onPressed: () {
                        // Mueve el mapa a la ubicación actual con zoom 15.
                        mapController.move(state.userLocation!, 15);
                      },
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),

                  // Panel inferior deslizable que contiene listado y controles.
                  NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      // Actualiza posiciones y tamaño para animar el FAB al deslizar.
                      setState(() {
                        _widgetHeight = context.size!.height;
                        _dragScrollSheetExtent = notification.extent;
                        _fabPosition = _dragScrollSheetExtent * _widgetHeight;
                      });
                      return true;
                    },
                    child: DraggableScrollableSheet(
                      initialChildSize: _initialSheetChildSize,
                      minChildSize: 0.2,
                      maxChildSize: 0.6,
                      snap: true,
                      builder: (context, scrollController) {
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
                              // Indicador visual para el panel deslizable.
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

                              // Encabezado con botón volver y título de ruta o general.
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    // Mostrar botón volver si hay ruta seleccionada.
                                    if (selectedRouteIndex != null)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedRouteIndex = null;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.arrow_back,
                                          size: 22,
                                        ),
                                      ),
                                    if (selectedRouteIndex != null)
                                      const SizedBox(width: 8),

                                    // Título dinámico: rutas disponibles o nombre de ruta.
                                    Expanded(
                                      child: Text(
                                        selectedRouteIndex == null
                                            ? AppLocalizations.of(
                                                context,
                                              )!.rutas_disponibles
                                            : state
                                                  .route[selectedRouteIndex!]
                                                  .name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    // Botón para ver lista general de rutas si está en vista ruta.
                                    if (selectedRouteIndex != null)
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            selectedRouteIndex = null;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.list,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        label: const Text(
                                          "Ver rutas",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Contenido principal: listas dependiendo de búsqueda y selección.
                              Expanded(
                                child: searchQuery.isNotEmpty
                                    ? ListView(
                                        controller: scrollController,
                                        children: [
                                          // Listado de rutas filtradas por búsqueda.
                                          ...filteredRoutes.map(
                                            (route) => ListTile(
                                              leading: const Icon(
                                                Icons.alt_route,
                                                color: Colors.blue,
                                              ),
                                              title: Text("Ruta ${route.name}"),
                                              onTap: () {
                                                // Centra el mapa en la ruta seleccionada.
                                                final center = LatLng(
                                                  (route.initialLatitude +
                                                          route.finalLatitude) /
                                                      2,
                                                  (route.initialLongitude +
                                                          route
                                                              .finalLongitude) /
                                                      2,
                                                );
                                                setState(() {
                                                  selectedRouteIndex = state
                                                      .route
                                                      .indexOf(route);
                                                });
                                                mapController.move(center, 14);
                                              },
                                            ),
                                          ),
                                          // Listado de POIs filtrados por búsqueda.
                                          ...filteredPois.map(
                                            (poi) => ListTile(
                                              leading: const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 28,
                                              ),
                                              title: Text(poi.nombre),
                                              subtitle: Text(
                                                poi.categorias.isNotEmpty
                                                    ? poi.categorias[0]
                                                    : '',
                                              ),
                                              onTap: () {
                                                // Centra el mapa en el POI seleccionado.
                                                mapController.move(
                                                  LatLng(
                                                    poi.latitud,
                                                    poi.longitud,
                                                  ),
                                                  16,
                                                );
                                              },
                                              trailing: GestureDetector(
                                                onTap: () {
                                                  // Navega a detalle del POI.
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          PoiScreen(poi),
                                                    ),
                                                  );
                                                },
                                                child: const Icon(Icons.add),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : selectedRouteIndex == null
                                    ? ListView.builder(
                                        controller: scrollController,
                                        itemCount: state.route.length,
                                        itemBuilder: (context, index) {
                                          final route = state.route[index];
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                            ),
                                            child: ListTile(
                                              leading: const Icon(
                                                Icons.alt_route,
                                                color: Colors.blue,
                                              ),
                                              title: Text(
                                                "${AppLocalizations.of(context)!.ruta} ${route.name}",
                                              ),
                                              trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.grey,
                                                size: 18,
                                              ),
                                              selected:
                                                  selectedRouteIndex == index,
                                              selectedTileColor:
                                                  Colors.blue.shade50,
                                              onTap: () {
                                                final center = LatLng(
                                                  (route.initialLatitude +
                                                          route.finalLatitude) /
                                                      2,
                                                  (route.initialLongitude +
                                                          route
                                                              .finalLongitude) /
                                                      2,
                                                );
                                                setState(() {
                                                  selectedRouteIndex = index;
                                                });
                                                mapController.move(center, 14);
                                              },
                                            ),
                                          );
                                        },
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        itemCount: state
                                            .route[selectedRouteIndex!]
                                            .pois
                                            .length,
                                        itemBuilder: (context, index) {
                                          final poi = state
                                              .route[selectedRouteIndex!]
                                              .pois[index];
                                          return ListTile(
                                            leading: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 28,
                                            ),
                                            title: Text(poi.nombre),
                                            subtitle: Text(
                                              poi.categorias.isNotEmpty
                                                  ? poi.categorias[0]
                                                  : '',
                                            ),
                                            onTap: () {
                                              mapController.move(
                                                LatLng(
                                                  poi.latitud,
                                                  poi.longitud,
                                                ),
                                                16,
                                              );
                                            },
                                            trailing: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PoiScreen(poi),
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
                      },
                    ),
                  ),

                  // Barra superior con campo búsqueda y botones.
                  Positioned(
                    top: 0,
                    right: 0,
                    left: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: const CircleBorder(),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                  // No resetear selectedRouteIndex cuando hay búsqueda.
                                  if (value.isNotEmpty) {
                                    selectedRouteIndex = selectedRouteIndex;
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                hintText:
                                    Localizations.of<MaterialLocalizations>(
                                      context,
                                      MaterialLocalizations,
                                    )!.searchFieldLabel,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(32.0),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: const CircleBorder(),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.search),
                          ),
                          const SizedBox(width: 4.0),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.pink,
                              shape: const CircleBorder(),
                            ),
                            onPressed: () {
                              // Navega a la pantalla de favoritos.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FavoritesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.favorite),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Mientras las rutas se cargan, muestra indicador de progreso.
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
