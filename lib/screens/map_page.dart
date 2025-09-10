import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';

class MapPage extends StatelessWidget {
  final String apiKey = 'JkdbhAS5977YOjkCqtYI';
  final MapController mapController = MapController();

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
                              'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$apiKey',
                          userAgentPackageName: 'com.colbun.app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (state.userLocation != null)
                              Marker(
                                point: state.userLocation!,
                                child: Transform.rotate(
                                  angle: state.heading * (3.1416 / 180),
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
                      ],
                    ),
                    buildBackButton(context),
                    if (state.userLocation != null) ...[
                      buildEmergencyButton(() {
                      }),
                      buildLocationButton(() {
                        mapController.move(state.userLocation!, 15);
                      }),
                    ],
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget buildBackButton(BuildContext context) => Positioned(
    top: 8,
    left: 8,
    child: IconButton(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.arrow_back_rounded),
    ),
  );

  Widget buildEmergencyButton(VoidCallback onTap) => Positioned(
    bottom: 80,
    right: 16,
    child: Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white24,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.phone_in_talk, color: Colors.white, size: 28),
          ),
        ),
      ),
    ),
  );

  Widget buildLocationButton(VoidCallback onTap) => Positioned(
    bottom: 16,
    right: 16,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFF4D67AE),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.my_location, color: Colors.white, size: 28),
        ),
      ),
    ),
  );
}
