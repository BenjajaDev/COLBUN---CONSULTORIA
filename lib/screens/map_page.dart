import 'dart:async';
import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:consultoria_chat_bot/data/map_repository.dart';
import 'package:consultoria_chat_bot/data/poi.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final String apiKey = 'JkdbhAS5977YOjkCqtYI';
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  final _repo = MapRepository();
  final String _routeId = 'los_bellotos';
  List<Poi> _pois = [];
  StreamSubscription<List<Poi>>? _poisSub;

  @override
  void initState() {
    super.initState();
    _poisSub = _repo.streamPoisByRoute(_routeId).listen((list) {
      setState(() => _pois = list);
    });
  }

  @override
  void dispose() {
    _poisSub?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _showPoiSheet(Poi p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.category, size: 16),
                  const SizedBox(width: 6),
                  Text(p.category),
                ],
              ),
              const SizedBox(height: 12),
              Text(p.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      mapController.move(p.location, 16);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.place),
                    label: const Text('Ir al punto'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            if (state is MapInitial) {
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
                        markers: _pois.map((p) {
                          return Marker(
                            point: p.location,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                             
                              behavior: HitTestBehavior.opaque, 
                              onTap: () => _showPoiSheet(p),
                              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                          );
                        }).toList(),
                      ), 
                    ],
                  ),


                      if (state.userLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: state.userLocation!,
                              child: Transform.rotate(
                                angle: state.heading * (3.1415926535 / 180),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4D67AE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.navigation, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),

                  // Barra superior
                  Positioned(
                    top: 0, right: 0, left: 0,
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
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
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
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapInitial && state.userLocation != null) {
            return FloatingActionButton(
              backgroundColor: const Color(0xFF4D67AE),
              onPressed: () => mapController.move(state.userLocation!, 15),
              child: const Icon(Icons.my_location, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

