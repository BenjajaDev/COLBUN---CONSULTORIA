import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Poi {
  final String id;
  final String name;
  final String category;
  final String description;
  final LatLng location;
  final int order;

  Poi({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.order,
  });

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory Poi.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final lat = data['lat'];
    final lng = data['lng'];


    final LatLng loc = (lat is GeoPoint && lng is GeoPoint)
        ? LatLng(lat.latitude, lng.longitude)
        : LatLng(_toDouble(lat), _toDouble(lng));

    return Poi(
      id: doc.id,
      name: (data['name'] ?? doc.id).toString(),
      category: (data['category'] ?? 'otros').toString(),
      description: (data['description'] ?? '').toString(),
      location: loc,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}

