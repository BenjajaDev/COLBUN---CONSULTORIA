import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:latlong2/latlong.dart';

abstract class PoiEvent {}

class LoadPoi extends PoiEvent {
  final POI current;
  final List<POI> all;
  final LatLng? userLocation;


  LoadPoi({
    required this.current,
    required this.all,
    this.userLocation,
  });

}