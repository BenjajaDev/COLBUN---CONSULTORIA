import 'dart:math' as math;

import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:consultoria_chat_bot/screens/favorites_screen.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter/material.dart';
import '../widget/filter_modal.dart';
import 'available_pois_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const Color _primaryColor = Color(0xFF4D67AE);
  final String apiKey = 'vuobOOmhVcspXRuOBRRs';
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  int? selectedRouteIndex;
  final double _initialSheetChildSize = 0.25;
  double _dragScrollSheetExtent = 0;
  double _widgetHeight = 0;
  double _fabPosition = 0;
  Type? _lastStateType;

  final double _fabPositionPadding = 10;
  @override
  void initState() {
    BlocProvider.of<MapBloc>(context).add(LoadRoute());
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _fabPosition =
            _initialSheetChildSize * MediaQuery.of(context).size.height;
      });
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(MapLoaded state) {
    FocusScope.of(context).unfocus();

    final categories =
        state.allRoutes
            .expand(
              (r) => [
                if (r.category != null && r.category!.trim().isNotEmpty)
                  r.category!.trim(),
                ...r.pois.expand((p) => p.categorias.map((c) => c.trim())),
              ],
            )
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final seasons =
        state.allRoutes
            .map((r) => r.season?.trim())
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    double computedMaxDistance = state.allRoutes.fold<double>(
      0,
      (prev, route) => route.distanceKm != null && route.distanceKm! > prev
          ? route.distanceKm!
          : prev,
    );

    if (computedMaxDistance <= 0) computedMaxDistance = 100;
    if (computedMaxDistance < 10) computedMaxDistance = 10;
    if (computedMaxDistance > 200) computedMaxDistance = 200;

    final sliderDivisions = computedMaxDistance.round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FilterModal(
          categories: categories,
          seasons: seasons,
          computedMaxDistance: computedMaxDistance,
          sliderDivisions: sliderDivisions,
          initialCategory: state.selectedCategory,
          initialDistance: state.selectedDistanceKm ?? 0,
          initialSeason: state.selectedSeason,
          primaryColor: _primaryColor,
          searchController: searchController,
          onFiltersApplied: () {
            if (selectedRouteIndex != null && mounted) {
              setState(() {
                selectedRouteIndex = null;
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<MapBloc, MapState>(
          listener: (context, state) {
            if (state is MapError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          child: BlocBuilder<MapBloc, MapState>(
            builder: (context, state) {
              // Recalculate FAB position when changing between MapLoaded/MapNavigating (or any state type)
              final currentType = state.runtimeType;
              if (_lastStateType != currentType) {
                _lastStateType = currentType;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final height = MediaQuery.of(context).size.height;
                  setState(() {
                    _widgetHeight = height;
                    _dragScrollSheetExtent = _initialSheetChildSize;
                    _fabPosition = _initialSheetChildSize * height;
                  });
                });
              }
              if (state is MapLoaded) {
                if (searchController.text != state.query) {
                  searchController.value = TextEditingValue(
                    text: state.query,
                    selection: TextSelection.collapsed(
                      offset: state.query.length,
                    ),
                  );
                }

                if (selectedRouteIndex != null &&
                    (selectedRouteIndex! < 0 ||
                        selectedRouteIndex! >= state.filteredRoutes.length)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        selectedRouteIndex = null;
                      });
                    }
                  });
                }
              }
              if (state is MapNavigating) {
                final userPos = state.start;
                final route = state.routePoints;
                if (route.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (state.bearing != null) {
                      mapController.rotate(state.bearing!);
                    }
                    mapController.move(userPos, 16.5); // zoom centrado
                  });
                }
              }
              return Stack(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateX(state is MapNavigating ? 0.6 : 0.0),
                    child: FlutterMap(
                      mapController: mapController,

                      options: MapOptions(
                        initialCenter: LatLng(-35.6960057, -71.4060907),

                        initialZoom: 15,
                        // Testing helper: tap the map to update the user's position
                        onTap: (tapPosition, point) {
                          try {
                            // Move the visible map to the tapped point
                            // Use a fixed zoom when centering on tap for testing
                            mapController.move(point, 15.0);
                            // Dispatch an UpdateUserLocation for quick testing (not altering bloc structure)
                            context.read<MapBloc>().add(UpdateUserLocation(point));
                          } catch (e) {
                            // ignore errors in testing hook
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$apiKey',

                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (state is MapLoaded)
                              ...state.filteredPois.map(
                                (poi) => Marker(
                                  point: LatLng(poi.latitud, poi.longitud),
                                  width: 80,
                                  height: 60,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PoiScreen(poi),
                                        ),
                                      );
                                    },

                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            if (state is MapLoaded)
                              if (state.userLocation != null)
                                Marker(
                                  point: state.userLocation!,
                                  child: Transform.rotate(
                                    angle:
                                        state.heading *
                                        (3.1415926535 /
                                            180), //  Convertir a radianes

                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4D67AE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.navigation, // Flecha tipo brujula

                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            if (state is MapNavigating)
                              if (state.userLocation != null)
                                Marker(
                                  point: state.userLocation!,
                                  child: Builder(builder: (context) {
                                    // Use a safe bearing value; fall back to 0.0 if null
                                    final double bearingDeg = state.bearing ?? 0.0;
                                    final double angleRad = bearingDeg * (math.pi / 180);
                                    return Transform.rotate(
                                      angle: angleRad,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4D67AE),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.navigation, // Flecha tipo brujula
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                          ],
                        ),
                        if (state is MapLoaded)
                          PolylineLayer(
                            polylines: state.filteredRoutes.map((route) {
                              return Polyline(
                                points: [
                                  LatLng(
                                    route.initialLatitude,
                                    route.initialLongitude,
                                  ),
                                  LatLng(
                                    route.finalLatitude,
                                    route.finalLongitude,
                                  ),
                                ],
                                strokeWidth: 4.0,
                                color: Colors.red,
                              );
                            }).toList(),
                          ),
                        if (state is MapNavigating)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: state.routePoints,
                                strokeWidth: 5.0,
                                color: Colors.blueAccent,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: _fabPosition + _fabPositionPadding,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF4D67AE),
                      onPressed: () {
                        // Use the user's location when available, otherwise fall back to a default center
                        mapController.move(
                          state is MapLoaded && state.userLocation != null
                              ? state.userLocation!
                              : LatLng(-35.6960057, -71.4060907),
                          15,
                        ); // ðŸ‘ˆ Centrar
                      },
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                  if (state is MapLoaded)
                    NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        setState(() {
                          _widgetHeight = MediaQuery.of(context).size.height;
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
                          return AvailablePoisRoutesSheet(
                            state: state,
                            selectedRouteIndex: selectedRouteIndex,
                            onRouteSelected: (index) {
                              setState(() {
                                selectedRouteIndex = index;
                              });
                            },
                            onClearSelectedRoute: () {
                              setState(() {
                                selectedRouteIndex = null;
                              });
                            },
                            onMoveMap: (LatLng center, {double? zoom}) {
                              mapController.move(center, zoom ?? 14);
                            },
                            setSelectedRouteIndex: (int? index) {
                              setState(() {
                                selectedRouteIndex = index;
                              });
                            },
                            primaryColorOpacity: 0.12,
                            primaryColor: _primaryColor,
                            mapController: mapController,
                            scrollController: scrollController,
                          );
                        },
                      ),
                    ),
                  if (state is MapNavigating)
                    NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        setState(() {
                          _widgetHeight = MediaQuery.of(context).size.height;
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
                          // compute distance/time/eta from instructions
                          final List<Map<String, dynamic>> instructions =
                              state.instructions;
                          double distanceMeters = 0.0;
                          double durationSeconds = 0.0;
                          for (final ins in instructions) {
                            distanceMeters +=
                                (ins['distance'] as num?)?.toDouble() ?? 0.0;
                            durationSeconds +=
                                (ins['duration'] as num?)?.toDouble() ?? 0.0;
                          }

                          String distanceText;
                          if (distanceMeters < 1000) {
                            distanceText = '${distanceMeters.round()} m';
                          } else {
                            distanceText =
                                '${(distanceMeters / 1000).toStringAsFixed(1)} km';
                          }

                          String durationText;
                          final dur = Duration(
                            seconds: durationSeconds.round(),
                          );
                          if (dur.inHours > 0) {
                            durationText =
                                '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
                          } else {
                            durationText = '${dur.inMinutes} min';
                          }

                          final eta = DateTime.now().add(dur);
                          final etaText = TimeOfDay.fromDateTime(
                            eta,
                          ).format(context);
                          print("📍 Posición actual: ${state.userLocation}");
                          print("➡️ Instrucción: ${state.instructions.first}");
                          print("🧭 Bearing: ${state.bearing}");
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
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  20,
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Ruta en curso',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.map,
                                                    color: Colors.black54,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Distancia: $distanceText',
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    color: Colors.black54,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Tiempo aprox: $durationText',
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.schedule,
                                                    color: Colors.black54,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Llegada aprox: $etaText',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF4D67AE),
                                          ),
                                          onPressed: () {
                                            // cancel navigation
                                            context.read<MapBloc>().add(
                                              CancelNavigation(),
                                            );
                                          },
                                          child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (state is MapLoaded)
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
                                foregroundColor: _primaryColor,
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
                                  context.read<MapBloc>().add(
                                    SearchQueryUpdated(value),
                                  );
                                },
                                decoration: InputDecoration(
                                  hintText:
                                      Localizations.of<MaterialLocalizations>(
                                        context,
                                        MaterialLocalizations,
                                      )!.searchFieldLabel,
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(32.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(32.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(32.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFF4D67AE),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 10.0,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 4.0),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryColor,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () => _openFilterSheet(state),
                              icon: const Icon(Icons.filter_list),
                            ),

                            /* const SizedBox(width: 4.0),
                            IconButton(
                              style: buttonStyle,
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                _sendQueryUpdate(state, searchController.text);
                              },
                              icon: const Icon(Icons.search),
                            ),*/
                            const SizedBox(width: 4.0),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.pink,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FavoritesScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.favorite),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (state is MapNavigating) ...[
                    Positioned(
                      top: 20,
                      left: 16,
                      right: 16,
                      child: _buildCurrentInstructionBanner(state.instructions),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentInstructionBanner(
    List<Map<String, dynamic>> instructions,
  ) {
    if (instructions.isEmpty) return const SizedBox.shrink();

    final current = instructions.first;
    final instruction = current['instruction'] ?? '';
    final distance = current['distance'] ?? 0.0;

    String distanceText;
    if (distance < 1000) {
      distanceText = '${distance.toStringAsFixed(0)} m';
    } else {
      distanceText = '${(distance / 1000).toStringAsFixed(1)} km';
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF4D67AE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.navigation, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distanceText,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
