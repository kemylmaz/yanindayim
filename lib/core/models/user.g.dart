// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      mode: fields[1] as UserMode,
      name: fields[2] as String?,
      bloodType: fields[3] as String?,
      medicalFlags: (fields[4] as List).cast<String>(),
      emergencyContacts: (fields[5] as List).cast<EmergencyContact>(),
      rescuerCreds: fields[6] as RescuerCredentials?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.bloodType)
      ..writeByte(4)
      ..write(obj.medicalFlags)
      ..writeByte(5)
      ..write(obj.emergencyContacts)
      ..writeByte(6)
      ..write(obj.rescuerCreds)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
