// Clase que representa un Punto de Interés (POI) con sus atributos principales.
class POI {
  final String id; // Identificador único del POI.
  final String nombre; // Nombre del POI.
  final Map<String, dynamic>
  descripcion; // Descripción detallada, estructura flexible.
  final String imagen; // URL o ruta de la imagen representativa.
  final double latitud; // Coordenada geográfica de latitud.
  final double longitud; // Coordenada geográfica de longitud.
  final List<String> categorias; // Categorías a las que pertenece el POI.
  final List<String> actividades; // Actividades disponibles en el POI.
  final Map<String, dynamic>
  vistas360; // Datos relacionados con vistas 360 grados, estructura flexible.

  // Constructor con todos los campos requeridos para crear una instancia de POI.
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
