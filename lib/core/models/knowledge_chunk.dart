import 'package:hive/hive.dart';

part 'knowledge_chunk.g.dart';

@HiveType(typeId: 5)
class KnowledgeChunk {
  @HiveField(0)
  String id;

  @HiveField(1)
  String source;

  @HiveField(2)
  String category;

  @HiveField(3)
  String text;

  @HiveField(4)
  List<double> embedding;

  KnowledgeChunk({
    required this.id,
    required this.source,
    required this.category,
    required this.text,
    required this.embedding,
  });
}
