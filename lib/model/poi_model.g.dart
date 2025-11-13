// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class POIAdapter extends TypeAdapter<POI> {
  @override
  final int typeId = 1;

  @override
  POI read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return POI(
      id: fields[0] as String,
      nombre: fields[1] as String,
      descripcion: (fields[2] as Map).cast<String, dynamic>(),
      imagen: fields[3] as String,
      latitud: fields[4] as double,
      longitud: fields[5] as double,
      categorias: (fields[6] as List).cast<String>(),
      actividades: (fields[7] as List).cast<String>(),
      vistas360: (fields[8] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, POI obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.imagen)
      ..writeByte(4)
      ..write(obj.latitud)
      ..writeByte(5)
      ..write(obj.longitud)
      ..writeByte(6)
      ..write(obj.categorias)
      ..writeByte(7)
      ..write(obj.actividades)
      ..writeByte(8)
      ..write(obj.vistas360);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is POIAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
