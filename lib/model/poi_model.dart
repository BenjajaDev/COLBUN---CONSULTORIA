class POI  {
  final String id;
  final String nombre;
  final Map<String, dynamic> descripcion;
  final String imagen;
  final double latitud;
  final double longitud;
  final List<String> categorias;
  final List<String> actividades;
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