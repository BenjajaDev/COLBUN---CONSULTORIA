abstract class PoiState {}

class POI extends PoiState {
  final String nombre;
  final String descripcion;
  final String imagen;
  final double latitud;
  final double longitud;
  final List<String> categorias;
  final List<String> actividades;
  final List<String> vistas360;

  POI({
    this.nombre = 'Parque Las Vizcachas de Rari',
    this.descripcion = 'El Parque Las Vizcachas de Rari es un espacio natural ubicado en la comuna de Colbún, en la Región del Maule, Chile. Este parque es conocido por su belleza escénica y su biodiversidad, ofreciendo a los visitantes la oportunidad de disfrutar de la naturaleza y realizar diversas actividades al aire libre. El parque cuenta con senderos para caminatas, áreas de picnic y miradores que permiten apreciar el paisaje circundante, incluyendo vistas panorámicas de las montañas y el río Colbún. Además, es un lugar ideal para la observación de aves y la fotografía de la flora y fauna local. El Parque Las Vizcachas de Rari es un destino popular tanto para los residentes locales como para los turistas que buscan escapar del bullicio de la ciudad y conectarse con la naturaleza.',
    this.imagen = 'https://upload.wikimedia.org/wikipedia/commons/2/2f/Letrero_Las_Vizcachas_de_Rari.jpg',
    this.latitud = -35.5833,
    this.longitud = -71.4167,
    this.categorias = const ['Naturaleza', 'Aventura'],
    this.actividades = const ['Senderismo', 'Picnic'],
    this.vistas360 = const[],
  });
}