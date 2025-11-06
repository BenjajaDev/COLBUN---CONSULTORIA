import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// 🔹 Eventos principales del mapa
abstract class MapEvent {}

/// Cargar rutas desde Firebase
class LoadRoute extends MapEvent {}

/// Agregar un marcador manual
class AddMarker extends MapEvent {
  final LatLng position;
  AddMarker(this.position);
}

/// Actualizar ubicación del usuario
class UpdateUserLocation extends MapEvent {
  final LatLng position;
  UpdateUserLocation(this.position);
}

/// Actualizar la orientación del usuario (brújula)
class UpdateHeading extends MapEvent {
  final double heading;
  UpdateHeading(this.heading);
}

/// Aplicar filtros (categoría, actividad, distancia, temporada)
class ApplyFilters extends MapEvent {
  final String? query;
  final String? category;
  final String? activity;
  final double? distanceKm;
  final String? season;

  ApplyFilters({
    this.query,
    this.category,
    this.activity,
    this.distanceKm,
    this.season,
  });
}

/// 🔍 Evento: actualización del texto de búsqueda
class SearchQueryUpdated extends MapEvent {
  final String query;
  SearchQueryUpdated(this.query);
}

/// 🚗 Evento: solicitar navegación a un punto de interés
class RequestNavigation extends MapEvent {
  final LatLng destination;
  final String languageCode;
  RequestNavigation(this.destination, this.languageCode);
}

/// 🚦 Evento: detener navegación
class CancelNavigation extends MapEvent {}

class AppLifecycleChanged extends MapEvent {
  final AppLifecycleState state;
  AppLifecycleChanged(this.state);
}
