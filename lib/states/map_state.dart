import 'package:latlong2/latlong.dart';

abstract class MapState {}

class MapInitial extends MapState {
  final LatLng center;
  final List<LatLng> markers;
  final LatLng? userLocation;
  final double heading;

  MapInitial({
    this.center = const LatLng(0, 0),
    this.markers = const [],
    this.userLocation,
    this.heading = 0.0,
  });
}
