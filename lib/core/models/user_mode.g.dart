// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModeAdapter extends TypeAdapter<UserMode> {
  @override
  final int typeId = 1;

  @override
  UserMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserMode.victim;
      case 1:
        return UserMode.rescuer;
      default:
        return UserMode.victim;
    }
  }

  @override
  void write(BinaryWriter writer, UserMode obj) {
    switch (obj) {
      case UserMode.victim:
        writer.writeByte(0);
        break;
      case UserMode.rescuer:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
