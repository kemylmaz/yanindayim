// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rescuer_credentials.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RescuerCredentialsAdapter extends TypeAdapter<RescuerCredentials> {
  @override
  final int typeId = 3;

  @override
  RescuerCredentials read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RescuerCredentials(
      organization: fields[0] as String,
      certificateNumber: fields[1] as String,
      specialty: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RescuerCredentials obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.organization)
      ..writeByte(1)
      ..write(obj.certificateNumber)
      ..writeByte(2)
      ..write(obj.specialty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RescuerCredentialsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
