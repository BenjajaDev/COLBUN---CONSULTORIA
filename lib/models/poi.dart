import 'package:latlong2/latlong.dart';

// Clase que representa un Punto de Interés (POI) con título, categoría, posición y orden.
class Poi {
  final String title; // Título o nombre del POI.
  final String category; // Categoría a la que pertenece el POI.
  final LatLng
  position; // Posición geográfica representada por latitud y longitud.
  final int order; // Orden o prioridad para listar o mostrar.

  // Constructor que requiere todos los campos para crear un POI.
  Poi({
    required this.title,
    required this.category,
    required this.position,
    required this.order,
  });

  // Factory para crear una instancia de Poi a partir de un mapa de datos (por ejemplo, JSON).
  factory Poi.fromMap(Map<String, dynamic> m) {
    return Poi(
      title: (m['title'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      position: LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      ),
      order: (m['order'] as num?)?.toInt() ?? 0,
    );
  }

  // Convierte la instancia de Poi en un mapa de datos para almacenamiento o transmisión.
  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'lat': position.latitude,
    'lng': position.longitude,
    'order': order,
  };
}
