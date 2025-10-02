import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultoria_chat_bot/models/route360.dart';

// Interfaz abstracta que define la obtención de rutas como lista o stream.
abstract class RoutesRepository {
  // Método para obtener la lista completa de rutas de forma asíncrona.
  Future<List<Route360>> fetchRoutes();

  // Método para obtener un stream de rutas que actualiza automáticamente.
  Stream<List<Route360>> streamRoutes();
}

// Implementación concreta que utiliza Firestore para obtener las rutas.
class RoutesRepositoryFirebase implements RoutesRepository {
  final FirebaseFirestore db;
  final String collectionName;

  // Constructor que recibe la instancia de Firestore y el nombre de colección (default 'rutas').
  RoutesRepositoryFirebase(this.db, {this.collectionName = 'rutas'});

  // Obtiene un snapshot de documentos de la colección y los convierte en una lista de rutas.
  @override
  Future<List<Route360>> fetchRoutes() async {
    final snap = await db.collection(collectionName).get();
    // Mapea cada documento a un objeto Route360 usando el método fromFirestore.
    return snap.docs
        .map((d) => Route360.fromFirestore(d.id, d.data()))
        .toList();
  }

  // Devuelve un stream que emite listas actualizadas de rutas cada vez que la colección cambia.
  @override
  Stream<List<Route360>> streamRoutes() {
    return db
        .collection(collectionName)
        .snapshots()
        .map(
          (qs) => qs.docs
              .map((d) => Route360.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }
}
