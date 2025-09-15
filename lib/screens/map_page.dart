import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:consultoria_chat_bot/models/route360.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  MapPage({super.key});

  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<MapBloc, MapState>(
          listenWhen: (previous, current) =>
              previous is MapInitial &&
              current is MapInitial &&
              previous.selectedRouteId != current.selectedRouteId,
          listener: (context, state) {
            if (state is MapInitial && state.selectedRouteId != null) {
              final route = state.routes.firstWhere(
                (r) => r.id == state.selectedRouteId,
                orElse: () => Route360(id: '', name: '', pois: const []),
              );
              if (route.pois.isNotEmpty) {
                final points = route.pois.map((p) => p.position).toList();
                if (points.length >= 2) {
                  final bounds = _boundsFromPoints(points);
                  mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 240),
                    ),
                  );
                } else {
                  mapController.move(points.first, 16);
                }
              }
            }
          },
          builder: (context, state) {
            if (state is MapFailure) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is! MapInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            final selected = state.selectedRouteId == null
                ? null
                : state.routes.firstWhere(
                    (r) => r.id == state.selectedRouteId,
                    orElse: () => Route360(id: '', name: '', pois: const []),
                  );
            return Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: state.center,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'consultoria_chat_bot',
                    ),
                    if (selected != null && selected.pois.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: selected.pois.map((e) => e.position).toList(),
                            strokeWidth: 4,
                          ),
                        ],
                      ),

                    MarkerLayer(
                      markers: [
                        if (selected != null)
                          ...selected.pois.map((p) {
                            return Marker(
                              point: p.position,
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(_iconFor(p.category), size: 20),
                                ),
                              ),
                            );
                          }),
                        if (state.userLocation != null)
                          Marker(
                            point: state.userLocation!,
                            width: 40,
                            height: 40,
                            child: Transform.rotate(
                              angle: state.heading * (3.1415926535 / 180.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4D67AE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.navigation,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

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
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: 'Buscar',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(32.0),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8.0),
                            ),
                            onSubmitted: (q) {
                            },
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                          },
                          icon: const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                ),

                DraggableScrollableSheet(
                  key: ValueKey(
                    selected == null ? 'list' : 'detail-${state.selectedRouteId}',
                  ),
                  initialChildSize: selected == null ? 0.22 : 0.25,
                  minChildSize: 0.18,
                  maxChildSize: 0.6,
                  builder: (context, controller) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: selected == null
                          ? ListView(
                              controller: controller,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                const ListTile(
                                  title: Text('Rutas',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const Divider(height: 0),
                                ...state.routes.map(
                                  (r) => ListTile(
                                    title: Text(r.name.isEmpty ? r.id : r.name),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context
                                        .read<MapBloc>()
                                        .add(SelectRoute(r.id)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            )
                          : ListView.builder(
                              controller: controller,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: selected.pois.length + 1,
                              itemBuilder: (ctx, i) {
                                if (i == 0) {
                                  return ListTile(
                                    leading: IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      tooltip: 'Volver',
                                      onPressed: () =>
                                          ctx.read<MapBloc>().add(DeselectRoute()),
                                    ),
                                    title: Text(
                                      selected.name.isEmpty
                                          ? selected.id
                                          : selected.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () =>
                                        ctx.read<MapBloc>().add(DeselectRoute()),
                                  );
                                }
                                final p = selected.pois[i - 1];
                                return ListTile(
                                  title: Text(p.title),
                                  subtitle: Text(p.category),
                                  trailing: const Icon(Icons.add),
                                  onTap: () => mapController.move(p.position, 16),
                                );
                              },
                            ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),

      floatingActionButton: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapInitial && state.userLocation != null) {
            return FloatingActionButton(
              backgroundColor: const Color(0xFF4D67AE),
              onPressed: () {
                mapController.move(state.userLocation!, 15);
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> pts) {
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  IconData _iconFor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('museo')) return Icons.museum_outlined;
    if (c.contains('parque')) return Icons.park_outlined;
    if (c.contains('artesanía') || c.contains('artesania')) {
      return Icons.storefront_outlined;
    }
    if (c.contains('eco')) return Icons.eco_outlined;
    return Icons.location_on_outlined;
  }
}
