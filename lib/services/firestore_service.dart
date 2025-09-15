

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';

class FireStoreService {
  final CollectionReference _poiCollection = FirebaseFirestore.instance
      .collection('poi');

  Future<POI> fetchPOI(String id) async {
  try {
    final doc = await _poiCollection.doc(id).get();

    if (!doc.exists) {
      // Return a default empty POI or throw an exception
      return POI(
        id: id,
        nombre: '',
        descripcion: {},
        imagen: '',
        latitud: 0.0,
        longitud: 0.0,
        categorias: [],
        actividades: [],
        vistas360: [],

      );
    }

    final data = doc.data() as Map<String, dynamic>;
    // Cambia esto según la configuración de idioma actua
    return POI(
      id: doc.id,
      nombre: data['nombre'].toString(),
      descripcion: Map<String, dynamic>.from(data['descripcion']),
      imagen: data['imagen'].toString(),
      latitud: (data['latitud'] ?? 0).toDouble(),
      longitud: (data['longitud'] ?? 0).toDouble(),
      categorias: List<String>.from(data['categoria'] ?? []),
      actividades: List<String>.from(data['actividades'] ?? []),
      vistas360: List<String>.from(data['vistas360'] ?? []),
    );
  } catch (e) {
    throw Exception('Error fetching POI: $e');
  }
}
}
