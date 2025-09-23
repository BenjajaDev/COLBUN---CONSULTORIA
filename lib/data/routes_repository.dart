import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultoria_chat_bot/models/route360.dart';

abstract class RoutesRepository {
  Future<List<Route360>> fetchRoutes();
  Stream<List<Route360>> streamRoutes();
}

class RoutesRepositoryFirebase implements RoutesRepository {
  final FirebaseFirestore db;
  final String collectionName; 

  RoutesRepositoryFirebase(
    this.db, {
    this.collectionName = 'rutas', 
  });

  @override
  Future<List<Route360>> fetchRoutes() async {
    final snap = await db.collection(collectionName).get();
    return snap.docs.map((d) => Route360.fromFirestore(d.id, d.data())).toList();
  }

  @override
  Stream<List<Route360>> streamRoutes() {
    return db.collection(collectionName).snapshots().map(
      (qs) => qs.docs.map((d) => Route360.fromFirestore(d.id, d.data())).toList(),
    );
  }
}

