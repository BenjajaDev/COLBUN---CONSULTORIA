import 'package:latlong2/latlong.dart';

abstract class MapState {}

class MapInitial extends MapState {
  final LatLng center;
  final List<LatLng> markers;
  final double heading;
  final LatLng? userLocation;

  MapInitial({
    required this.center,
    this.markers = const [],
    this.heading = 0.0,
    this.userLocation,
  });
}