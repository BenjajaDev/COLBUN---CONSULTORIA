import 'package:consultoria_chat_bot/blocs/map_bloc';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

class MapPage extends StatelessWidget {
  final String apiKey = 'vuobOOmhVcspXRuOBRRs';
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapBloc(),
      child: Scaffold(
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
                          markers: [
                            ...state.markers.map(
                              (marker) => Marker(
                                point: marker,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ),
                            if (state.userLocation != null)
                              Marker(
                                point: state.userLocation!,
                                child: Transform.rotate(
                                  angle:
                                      state.heading *
                                      (3.1415926535 /
                                          180), // 🔥 Convertir a radianes
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4D67AE),
                                      shape: BoxShape.circle,  
                                    ),
                                    child: const Icon(
                                      
                                      Icons.navigation, // Flecha tipo brújula
                                      color: Colors.white,
                                      size: 24,
                                    ),
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
                              onPressed: () {},
                              icon: Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: Localizations.of<MaterialLocalizations>(context, MaterialLocalizations)!.searchFieldLabel,
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
                              icon: Icon(Icons.search),
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
                onPressed: () {
                  mapController.move(state.userLocation!, 15); // 👈 Centrar
                },
                child: const Icon(Icons.my_location, color: Colors.white),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
