import 'package:latlong2/latlong.dart';

class Poi {
  final String title;
  final String category;
  final LatLng position;
  final int order;

  Poi({
    required this.title,
    required this.category,
    required this.position,
    required this.order,
  });

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

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'lat': position.latitude,
        'lng': position.longitude,
        'order': order,
      };
}
