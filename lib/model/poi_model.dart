import 'package:hive/hive.dart'; // 1. Importa HIVE

part 'poi_model.g.dart'; // 2. Añade esta línea (mostrará un error por ahora)

@HiveType(typeId: 1) // 3. Identificador ÚNICO de la clase (usaremos 0 para la Ruta)
class POI {
  
  @HiveField(0) // 4. Índice del campo (debe ser secuencial)
  final String id;
  
  @HiveField(1)
  final String nombre;
  
  @HiveField(2)
  final Map<String, dynamic> descripcion; // Hive puede guardar Mapas
  
  @HiveField(3)
  final String imagen;
  
  @HiveField(4)
  final double latitud;
  
  @HiveField(5)
  final double longitud;
  
  @HiveField(6)
  final List<String> categorias; // Hive puede guardar Listas
  
  @HiveField(7)
  final List<String> actividades;
  
  @HiveField(8)
  final Map<String, dynamic> vistas360;

  POI({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagen,
    required this.latitud,
    required this.longitud,
    required this.categorias,
    required this.actividades,
    required this.vistas360,
  });
}