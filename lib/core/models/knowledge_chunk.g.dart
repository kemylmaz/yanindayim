// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_chunk.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KnowledgeChunkAdapter extends TypeAdapter<KnowledgeChunk> {
  @override
  final int typeId = 5;

  @override
  KnowledgeChunk read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KnowledgeChunk(
      id: fields[0] as String,
      source: fields[1] as String,
      category: fields[2] as String,
      text: fields[3] as String,
      embedding: (fields[4] as List).cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, KnowledgeChunk obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.source)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.text)
      ..writeByte(4)
      ..write(obj.embedding);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeChunkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
