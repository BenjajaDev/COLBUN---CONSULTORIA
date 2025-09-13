import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final _db = FirebaseFirestore.instance;

  Future<void> seed() async {

    await _upsertRoute(
      id: 'los_bellotos',
      name: 'Los Bellotos',
      color: '#4D67AE',
      pois: _losBellotosPois,
    );


    await _upsertRoute(
      id: 'quinamavida',
      name: 'Quinamávida',
      color: '#0F9D58',
      pois: _quinamavidaPois,
    );
  }

  Future<void> _upsertRoute({
    required String id,
    required String name,
    required String color,
    required List<Map<String, dynamic>> pois,
  }) async {
    final routeRef = _db.collection('routes').doc(id);

    
    await routeRef.set({'name': name, 'color': color}, SetOptions(merge: true));

    final batch = _db.batch();
    for (final p in pois) {
      
      final doc = routeRef.collection('pois').doc(p['id'] as String);
      batch.set(doc, p, SetOptions(merge: true));
    }
    await batch.commit();
  }
}


final List<Map<String, dynamic>> _losBellotosPois = [
  {
    'id': 'las_cavernas',
    'name': 'Las cavernas, Los Bellotos',
    'category': 'naturaleza',
    'description':
        'Sendero ida y vuelta (~7,2 km) dentro de la Reserva Nacional Los Bellotos del Melado. Dificultad moderada.',
    'lat': -35.8881084192906,
    'lng': -71.11984545735982, 
    'order': 1,
  },
  {
    'id': 'cascada_castillo',
    'name': 'Cascada Castillo',
    'category': 'naturaleza',
    'description':
        'Caída de agua dentro de la reserva. Bosque nativo, rocas y senderos de trekking.',
    'lat': -35.91213638388591, 
    'lng': -71.12723084554298, 
    'order': 2,
  },
  {
    'id': 'rio_ancoa',
    'name': 'Río Ancoa',
    'category': 'naturaleza',
    'description':
        'Río cordillerano; pesca recreativa, picnic y caminatas en sus riberas.',
    'lat': -35.85921500179679, 
    'lng': -71.2255941198833,
    'order': 3,
  },
  {
    'id': 'sector_hornillos',
    'name': 'Sector Los Bellotos',
    'category': 'naturaleza',
    'description':
        'Zona de valor histórico-ingenieril. Atractivo principal: túnel del Canal Melado.',
    'lat': -35.867690319200754, 
    'lng': -71.11744350864545, 
    'order': 4,
  },
  {
    'id': 'reserva_nacional_los_bellotos',
    'name': 'Reserva Nacional Los Bellotos',
    'category': 'naturaleza',
    'description':
        'Unidad de conservación que protege el belloto del sur y otros valores naturales.',
    'lat': -35.85801988653018, 
    'lng': -71.10435162549044, 
    'order': 5,
  },
  {
    'id': 'el_melado_lodge',
    'name': 'El Melado Lodge',
    'category': 'alojamiento',
    'description':
        'Lodge de montaña; base para senderismo y observación de fauna. Habitaciones con baño privado.',
    'lat': -35.862055906610244, 
    'lng': -71.12328085597542, 
    'order': 6,
  },
];


final List<Map<String, dynamic>> _quinamavidaPois = [
  {
    'id': 'mirador_ngen',
    'name': 'Mirador Ñgen',
    'category': 'naturaleza',
    'description':
        'Punto panorámico con vistas cordilleranas. Actividades: trekking, fotografía.',
    'lat': -35.81530022145429, 
    'lng': -71.40608180066249, 
    'order': 1,
  },
  {
    'id': 'hotel_quinamavida',
    'name': 'Hotel Quinamávida',
    'category': 'alojamiento',
    'description':
        'Complejo turístico reconocido por termas, spa y servicios de alojamiento.',
    'lat': -35.79551670656776, 
    'lng': -71.42638257589861, 
    'order': 2,
  },
  {
    'id': 'country_lodge_nogales',
    'name': 'Country Lodge Los Nogales de Quinamávida',
    'category': 'alojamiento',
    'description':
        'Lodge campestre rodeado de naturaleza. Descanso y actividades al aire libre.',
    'lat': -35.820056383692716, 
    'lng': -71.42571209069787, 
    'order': 3,
  },
  {
    'id': 'centro_recreacional_impch',
    'name':
        'Centro Recreacional Quinamávida — Iglesia Metodista Pentecostal de Chile',
    'category': 'recreacion',
    'description':
        'Espacio recreativo con áreas verdes y actividades comunitarias.',
    'lat': -35.798296951983644, 
    'lng': -71.44770204697903, 
    'order': 4,
  },
  {
    'id': 'rasam_chile_piedra_onix',
    'name': 'Rasam Chile — Taller Piedra Ónix',
    'category': 'cultura',
    'description':
        'Taller y sala de exposición de piedra ónix típica de la zona; artesanías y souvenirs.',
    'lat': -35.80384531428168, 
    'lng': -71.43740337362003, 
    'order': 5,
  },
  {
    'id': 'restaurant_estelita',
    'name': 'Restaurant Estelita',
    'category': 'gastronomia',
    'description':
        'Cocina casera y platos tradicionales de la zona.',
    'lat': -35.78563084975659, 
    'lng': -71.44091739538031, 
    'order': 6,
  },
  {
    'id': 'cabanas_puertas_quinamavida',
    'name': 'Cabañas Puertas de Quinamávida',
    'category': 'alojamiento',
    'description':
        'Complejo de cabañas turísticas. Ideal para familias o grupos, cercano a termas y rutas.',
    'lat': -35.79938812321781, 
    'lng': -71.44507506205608, 
    'order': 7,
  },
];

