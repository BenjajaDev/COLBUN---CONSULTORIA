import 'package:latlong2/latlong.dart';
import 'poi.dart';

class Route360 {
  final String id;
  final String name;
  final List<Poi> pois;

  Route360({required this.id, required this.name, required this.pois});

  factory Route360.fromFirestore(String id, Map<String, dynamic> data) {
    final rawPois = (data['pois'] as List? ?? [])
        .map((e) => Poi.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Route360(id: id, name: (data['name'] ?? '').toString(), pois: rawPois);
  }

  List<LatLng> get points => pois.map((p) => p.position).toList();
}
