// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beacon.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BeaconAdapter extends TypeAdapter<Beacon> {
  @override
  final int typeId = 4;

  @override
  Beacon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Beacon(
      anonymousId: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      batteryPercent: fields[3] as int,
      bloodType: fields[4] as String,
      medicalFlags: (fields[5] as List).cast<String>(),
      broadcastStarted: fields[6] as DateTime,
      rssi: fields[7] as int?,
      lastSeen: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Beacon obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.anonymousId)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.batteryPercent)
      ..writeByte(4)
      ..write(obj.bloodType)
      ..writeByte(5)
      ..write(obj.medicalFlags)
      ..writeByte(6)
      ..write(obj.broadcastStarted)
      ..writeByte(7)
      ..write(obj.rssi)
      ..writeByte(8)
      ..write(obj.lastSeen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeaconAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
