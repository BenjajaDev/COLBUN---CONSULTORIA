
abstract class PoiEvent {}

class LoadPoi extends PoiEvent {
  final String id;
  LoadPoi(this.id);
}
