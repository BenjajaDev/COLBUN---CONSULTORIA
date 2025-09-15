import 'package:latlong2/latlong.dart';
import 'package:consultoria_chat_bot/models/route360.dart';


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

class SubscribeRoutes extends MapEvent {}  
class LoadRoutes extends MapEvent {}

class RoutesUpdated extends MapEvent {         
  final List<Route360> routes;
  RoutesUpdated(this.routes);
}
class SelectRoute extends MapEvent {
  final String routeId;
  SelectRoute(this.routeId);
}

class DeselectRoute extends MapEvent {}