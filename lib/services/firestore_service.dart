import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/services/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:latlong2/latlong.dart';

class FireStoreService {
  final CollectionReference _routesCollection = FirebaseFirestore.instance
      .collection('ruta');
  DocumentSnapshot? _lastRouteDocument;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final sanitized = value.replaceAll(',', '.');
      return double.tryParse(sanitized);
    }
    return null;
  }

  void resetRoutesPagination() {
    _lastRouteDocument = null;
  }

  LatLng? _latLngFromMap(dynamic point) {
    if (point is Map) {
      final latValue = point['lat'] ?? point['latitude'];
      final lngValue = point['lng'] ?? point['longitude'];
      final lat = (latValue is num) ? latValue.toDouble() : double.tryParse('$latValue');
      final lng = (lngValue is num) ? lngValue.toDouble() : double.tryParse('$lngValue');
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  POI _poiFromFirestore(String id, Map<String, dynamic> data) {
    return POI(
      id: id,
      nombre: data['nombre']?.toString() ?? '',
      descripcion: Map<String, dynamic>.from(data['descripcion'] ?? {}),
      imagen: data['imagen']?.toString() ?? '',
      latitud: (data['latitud'] ?? 0).toDouble(),
      longitud: (data['longitud'] ?? 0).toDouble(),
      categorias: List<String>.from(data['categoria'] ?? data['categorias'] ?? []),
      actividades: List<String>.from(data['actividades'] ?? []),
      vistas360: Map<String, dynamic>.from(data['vistas360'] ?? {}),
    );
  }

  Future<List<POI>> fetchAllPOIs(String routeId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ruta')
          .doc(routeId)
          .collection('poi')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _poiFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching POIs: $e');
    }
  }

  Future<List<MapRoute>> fetchRoutes({int limit = 30, bool reset = false}) async {
    try {
      if (reset) {
        resetRoutesPagination();
      }

      Query query = _routesCollection
          .orderBy('nombre')
          .limit(limit);
      if (_lastRouteDocument != null) {
        query = query.startAfterDocument(_lastRouteDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastRouteDocument = snapshot.docs.last;
      }

      return snapshot.docs
          .where((doc) => doc.id.toString() != "sin_asignar")
          .map((doc) {
            final raw = doc.data();
            final data = raw is Map<String, dynamic>
                ? raw
                : Map<String, dynamic>.from(raw as Map);
            final geometry = (data['geometry'] as List? ?? [])
                .map(_latLngFromMap)
                .whereType<LatLng>()
                .toList();

            return MapRoute(
              id: doc.id,
              initialLatitude: (data['latitud_inicio'] ?? 0).toDouble(),
              initialLongitude: (data['longitud_inicio'] ?? 0).toDouble(),
              finalLatitude: (data['latitud_fin'] ?? 0).toDouble(),
              finalLongitude: (data['longitud_fin'] ?? 0).toDouble(),
              name: data['nombre']?.toString() ?? '',
              category: data['categoria']?.toString(),
              distanceKm:
                  _toDouble(data['distancia_km']) ??
                  _toDouble(data['distancia']) ??
                  _toDouble(data['distance_km']),
              season: data['temporada']?.toString(),
              pois: const <POI>[],
              geometry: geometry,
            );
          })
          .toList();
    } catch (e) {
      throw Exception('Error fetching Routes: $e');
    }
  }

  Future<Map<String, List<POI>>> fetchPoisForRoutes(List<String> routeIds) async {
    if (routeIds.isEmpty) return {};
    final Set<String> ids = routeIds.toSet();
    final Map<String, List<POI>> grouped = {
      for (final id in ids) id: <POI>[],
    };
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('poi')
          .get();

      for (final doc in snapshot.docs) {
        final parentRouteId = doc.reference.parent.parent?.id;
        final data = doc.data();
        final routeId = data['routeId']?.toString() ?? parentRouteId;
        if (routeId == null || !ids.contains(routeId)) {
          continue;
        }
        grouped.putIfAbsent(routeId, () => <POI>[]);
        grouped[routeId]!.add(_poiFromFirestore(doc.id, data));
      }
      return grouped;
    } catch (e) {
      throw Exception('Error fetching POIs for routes: $e');
    }
  }
  Future<List<Map<String, dynamic>>> fetchCategory(List<String> categories) async {
    try {
      if (categories.isEmpty) return [];

      final List<Map<String, dynamic>> results = [];

      // Firestore whereIn supports up to 10 items per query; chunk if necessary
      const chunkSize = 10;
      for (var i = 0; i < categories.length; i += chunkSize) {
        final chunk = categories.sublist(i, (i + chunkSize).clamp(0, categories.length));
        final querySnapshot = await FirebaseFirestore.instance
            .collection('categorias')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          try {
            final merged = Map<String, dynamic>.from(data);
            merged['id'] = doc.id;
            results.add(merged);
          } catch (_) {
            // ignore malformed doc
          }
        }
      }
      debugPrint('fetchCategory: found ${results.length} items');
      return results;
    } catch (e) {
      throw Exception('Error fetching Categories: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchActivity(List<String> activities) async {
    try {
      if (activities.isEmpty) return [];

      final List<Map<String, dynamic>> results = [];
      const chunkSize = 10;
      for (var i = 0; i < activities.length; i += chunkSize) {
        final chunk = activities.sublist(i, (i + chunkSize).clamp(0, activities.length));
        final querySnapshot = await FirebaseFirestore.instance
            .collection('actividades')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          try {
            final merged = Map<String, dynamic>.from(data);
            merged['id'] = doc.id;
            results.add(merged);
          } catch (_) {
            // ignore malformed doc
          }
        }
      }
      debugPrint('fetchActivity: found ${results.length} items');
      return results;
    } catch (e) {
      throw Exception('Error fetching Activities: $e');
    }
  }
  Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    try {
      final List<String> collections = ['emergency', 'emergencias'];
      QuerySnapshot? snapshot;
      for (final name in collections) {
        final snap = await FirebaseFirestore.instance.collection(name).get();
        if (snap.docs.isNotEmpty) {
          snapshot = snap;
          break;
        }
      }
      if (snapshot == null || snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? data['nombre'] ?? '').toString();
        final phone = (data['phone'] ?? data['telefono'] ?? '').toString();
        return EmergencyContact(name: name, phone: phone);
      }).toList();
    } catch (_) {
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchAllCategories() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('categorias').get();
    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...Map<String, dynamic>.from(data),
      };
    }).toList();
  } catch (_) {
    return [];
  }
}
  Future<List<Map<String, dynamic>>> fetchAllActivities() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('actividades').get();
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...Map<String, dynamic>.from(data),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
