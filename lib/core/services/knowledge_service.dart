// RAG: Bilgi Çıkarma Motoru
//Cihazı yormadan, sadece kelime eşleştirmesiyle chunks.json
//dosyasındaki en doğru bilgiyi
//bulup getirecek olan servisimizi yazıyoruz.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final knowledgeServiceProvider = Provider<KnowledgeService>((ref) {
  return KnowledgeService();
});

class KnowledgeService {
  List<Map<String, dynamic>> _chunks = [];
  bool _isLoaded = false;

  /// JSON dosyasını okuyup hafızaya alır
  Future<void> loadKnowledgeBase() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/knowledge_base/chunks.json',
      );
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> chunksList = jsonData['chunks'];

      _chunks = chunksList.map((e) => e as Map<String, dynamic>).toList();
      _isLoaded = true;
      debugPrint("Bilgi tabanı yüklendi: ${_chunks.length} parça veri.");
    } catch (e) {
      debugPrint("Bilgi tabanı yüklenirken hata: $e");
    }
  }

  /// Soruya en uygun metinleri bulur (Akıllı Kelime Eşleştirme)
  Future<String> getRelevantContext(String query) async {
    if (!_isLoaded) await loadKnowledgeBase();
    if (_chunks.isEmpty) return "";

    // 1. Basit NLP: Noktalama işaretlerini sil, küçük harfe çevir
    final normalizedQuery = query.toLowerCase().replaceAll(
      RegExp(r'[^\w\sğüşıöç]'),
      '',
    );
    final queryWords = normalizedQuery
        .split(' ')
        .where((w) => w.length > 2)
        .toList(); // Çok kısa bağlaçları atla

    if (queryWords.isEmpty) return "";

    // 2. Puanlama: Her chunk için kaç kelime eşleştiğini say
    List<Map<String, dynamic>> scoredChunks = [];

    for (var chunk in _chunks) {
      int score = 0;
      final chunkText = chunk['text'].toString().toLowerCase();

      for (var word in queryWords) {
        if (chunkText.contains(word)) {
          score++;
        }
      }

      if (score > 0) {
        scoredChunks.add({'text': chunk['text'], 'score': score});
      }
    }

    // 3. Eşleşme skoruna göre büyükten küçüğe sırala
    scoredChunks.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    // 4. En iyi 3 bilgiyi alıp birleştir
    final topChunks = scoredChunks
        .take(3)
        .map((e) => "- \${e['text']}")
        .toList();

    return topChunks.join('\n\n');
  }
}
