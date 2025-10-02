import 'package:consultoria_chat_bot/model/poi_model.dart';

// Clase que representa una ruta en el mapa, con sus coordenadas y POIs asociados.
class MapRoute {
  final String id; // Identificador único de la ruta.
  final double initialLatitude; // Latitud del punto inicial de la ruta.
  final double initialLongitude; // Longitud del punto inicial de la ruta.
  final double finalLatitude; // Latitud del punto final de la ruta.
  final double finalLongitude; // Longitud del punto final de la ruta.
  final String name; // Nombre descriptivo de la ruta.
  final List<POI>
  pois; // Lista de Puntos de Interés (POIs) asociados a la ruta.

  // Constructor con todos los campos requeridos para crear una instancia de MapRoute.
  MapRoute({
    required this.id,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.finalLatitude,
    required this.finalLongitude,
    required this.name,
    required this.pois,
  });
}
