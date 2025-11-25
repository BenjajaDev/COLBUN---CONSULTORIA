import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

// Este es el "traductor"
// Le damos un typeId único, ej: 100 (lejos de los otros)
class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  final int typeId = 100;

  @override
  LatLng read(BinaryReader reader) {
    // Leemos los dos 'doubles' que guardamos
    final lat = reader.readDouble();
    final lon = reader.readDouble();
    return LatLng(lat, lon);
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    // Guardamos los dos 'doubles' del objeto LatLng
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
  }
}