import 'package:cloud_firestore/cloud_firestore.dart';
import 'poi.dart';

class MapRepository {
  final _db = FirebaseFirestore.instance;

  Future<List<Poi>> fetchPoisByRoute(String routeId) async {
    final snap = await _db
        .collection('routes')
        .doc(routeId)
        .collection('pois')
        .orderBy('order')
        .get();

    return snap.docs.map((d) => Poi.fromFirestore(d)).toList();
  }

  Stream<List<Poi>> streamPoisByRoute(String routeId) {
    return _db
        .collection('routes')
        .doc(routeId)
        .collection('pois')
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map((d) => Poi.fromFirestore(d)).toList());
  }
}

