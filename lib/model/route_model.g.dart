// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MapRouteAdapter extends TypeAdapter<MapRoute> {
  @override
  final int typeId = 0;

  @override
  MapRoute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapRoute(
      id: fields[0] as String,
      initialLatitude: fields[1] as double,
      initialLongitude: fields[2] as double,
      finalLatitude: fields[3] as double,
      finalLongitude: fields[4] as double,
      name: fields[5] as String,
      pois: (fields[9] as List).cast<POI>(),
      geometry: (fields[10] as List).cast<LatLng>(),
      category: fields[6] as String?,
      distanceKm: fields[7] as double?,
      season: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MapRoute obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.initialLatitude)
      ..writeByte(2)
      ..write(obj.initialLongitude)
      ..writeByte(3)
      ..write(obj.finalLatitude)
      ..writeByte(4)
      ..write(obj.finalLongitude)
      ..writeByte(5)
      ..write(obj.name)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.distanceKm)
      ..writeByte(8)
      ..write(obj.season)
      ..writeByte(9)
      ..write(obj.pois)
      ..writeByte(10)
      ..write(obj.geometry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapRouteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
