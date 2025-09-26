import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final String apiKey = 'vuobOOmhVcspXRuOBRRs';
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  int? selectedRouteIndex;
  final double _initialSheetChildSize = 0.25;
  double _dragScrollSheetExtent = 0;
  double _widgetHeight = 0;
  double _fabPosition = 0;
  final double _fabPositionPadding = 10;

  String searchQuery = "";

  @override
  void initState() {
    BlocProvider.of<MapBloc>(context).add(LoadRoute());
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _fabPosition = _initialSheetChildSize * context.size!.height;
      });
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            if (state is MapLoaded) {
              final allPois = state.route
                  .expand((route) => route.pois)
                  .toList();

              // 🔍 Filtrado de rutas
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

              // 🔍 Filtrado de POIs
              final filteredPois = searchQuery.isEmpty
                  ? (selectedRouteIndex == null
                        ? allPois
                        : state.route[selectedRouteIndex!].pois)
                  : (selectedRouteIndex == null
                        ? allPois
                              .where(
                                (p) => p.nombre.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ),
                              )
                              .toList()
                        : state.route[selectedRouteIndex!].pois
                              .where(
                                (p) => p.nombre.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ),
                              )
                              .toList());

              return Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: state.center,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$apiKey',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          ...filteredPois.map(
                            (marker) => Marker(
                              point: LatLng(marker.latitud, marker.longitud),
                              width: 80,
                              height: 60,
                              child: GestureDetector(
                                onTap: () {
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

                  // FAB centrar usuario
                  Positioned(
                    bottom: _fabPosition + _fabPositionPadding,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF4D67AE),
                      onPressed: () {
                        if (state.userLocation != null) {
                          mapController.move(state.userLocation!, 15);
                        }
                      },
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),

                  // Drawer inferior
                  NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
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

                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
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

                              // Contenido
                              Expanded(
                                child: searchQuery.isNotEmpty
                                    ? ListView(
                                        controller: scrollController,
                                        children: [
                                          ...filteredRoutes.map(
                                            (route) => ListTile(
                                              leading: const Icon(
                                                Icons.alt_route,
                                                color: Colors.blue,
                                              ),
                                              title: Text("Ruta ${route.name}"),
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
                                                  selectedRouteIndex = state
                                                      .route
                                                      .indexOf(route);
                                                });
                                                mapController.move(center, 14);
                                              },
                                            ),
                                          ),
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
                                              Icons.location_on, // 📍
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

                  // 🔍 Barra de búsqueda
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
                                  if (value.isNotEmpty) {
                                    selectedRouteIndex =
                                        selectedRouteIndex; // 👈 no resetear ruta seleccionada
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
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
