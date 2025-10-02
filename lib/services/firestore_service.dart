import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';

// Servicio para obtener datos de Firestore, como rutas y POIs asociados.
class FireStoreService {
  // Referencia a la colección 'ruta' en Firestore.
  final CollectionReference _routesCollection = FirebaseFirestore.instance
      .collection('ruta');

  // Método que obtiene todos los POIs de una ruta específica identificada por routeId.
  Future<List<POI>> fetchAllPOIs(String routeId) async {
    try {
      // Consulta la subcolección 'poi' dentro del documento de la ruta.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ruta')
          .doc(routeId)
          .collection('poi')
          .get();

      // Mapea cada documento a una instancia de POI, extrayendo campos con validaciones y conversiones.
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return POI(
          id: doc.id,
          nombre: data['nombre']?.toString() ?? '',
          descripcion: Map<String, dynamic>.from(data['descripcion'] ?? {}),
          imagen: data['imagen']?.toString() ?? '',
          latitud: (data['latitud'] ?? 0).toDouble(),
          longitud: (data['longitud'] ?? 0).toDouble(),
          categorias: List<String>.from(data['categoria'] ?? []),
          actividades: List<String>.from(data['actividades'] ?? []),
          vistas360: Map<String, dynamic>.from(data['vistas360'] ?? {}),
        );
      }).toList();
    } catch (e) {
      // En caso de error propaga excepción con mensaje.
      throw Exception('Error fetching POIs: $e');
    }
  }

  // Método que obtiene todas las rutas en la colección 'ruta' incluyendo los POIs asociados.
  Future<List<MapRoute>> fetchRoutes() async {
    try {
      // Obtiene los documentos de la colección 'ruta'.
      final querySnapshot = await _routesCollection.get();

      List<MapRoute> routes = [];

      // Para cada documento, construye un MapRoute con sus campos y carga los POIs asociados.
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Await para obtener lista real de POIs de la ruta actual.
        final pois = await fetchAllPOIs(doc.id);

        routes.add(
          MapRoute(
            id: doc.id,
            initialLatitude: (data['latitud_inicio'] ?? 0).toDouble(),
            initialLongitude: (data['longitud_inicio'] ?? 0).toDouble(),
            finalLatitude: (data['latitud_fin'] ?? 0).toDouble(),
            finalLongitude: (data['longitud_fin'] ?? 0).toDouble(),
            name: data['nombre']?.toString() ?? '',
            pois: pois,
          ),
        );
      }

      return routes;
    } catch (e) {
      // Propaga excepción en caso de fallo general.
      throw Exception('Error fetching Routes: $e');
    }
  }
}
