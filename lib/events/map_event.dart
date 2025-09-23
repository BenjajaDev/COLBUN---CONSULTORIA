import 'package:latlong2/latlong.dart';


abstract class MapEvent {}

class AddMarker extends MapEvent {
  final LatLng position;
  AddMarker(this.position);
}
class UpdateUserLocation extends MapEvent {
  final LatLng position;
  UpdateUserLocation(this.position);
}
class UpdateHeading extends MapEvent {
  final double heading;
  UpdateHeading(this.heading);
}
class LoadRoute extends MapEvent {

}
