import 'package:latlong2/latlong.dart';
import 'poi.dart';

// Clase que representa una ruta con un id, nombre y lista ordenada de POIs.
class Route360 {
  final String id; // Identificador único de la ruta.
  final String name; // Nombre descriptivo de la ruta.
  final List<Poi> pois; // Lista de Puntos de Interés (POIs) ordenados.

  // Constructor que inicializa los campos obligatorios de la ruta.
  Route360({required this.id, required this.name, required this.pois});

  // Factory que crea una instancia de Route360 desde datos obtenidos de Firestore.
  factory Route360.fromFirestore(String id, Map<String, dynamic> data) {
    // Convierte la lista sin procesar de POIs en objetos Poi y los ordena por el campo 'order'.
    final rawPois =
        (data['pois'] as List? ?? [])
            .map((e) => Poi.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    // Retorna la ruta con id, nombre y lista de POIs ordenada.
    return Route360(
      id: id,
      name: (data['name'] ?? '').toString(),
      pois: rawPois,
    );
  }

  // Getter que devuelve la lista de posiciones latlong de todos los POIs en la ruta.
  List<LatLng> get points => pois.map((p) => p.position).toList();
}
