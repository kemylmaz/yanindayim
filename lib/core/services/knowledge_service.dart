// Bu servis, bilgi bankasındaki metinleri yükler ve
//kullanıcının sorusuyla eşleştirerek ilgili bilgiyi döndürür.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final knowledgeServiceProvider = Provider<KnowledgeService>((ref) {
  return KnowledgeService();
});

class KnowledgeService {
  List<Map<String, dynamic>> _chunks = [];

  // Senin verdiğin JSON yapısına göre dosyayı hafızaya yüklüyoruz
  Future<void> loadKnowledge() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/knowledge_base/chunks.json',
      );
      final Map<String, dynamic> data = json.decode(response);

      // En dıştaki objeden "chunks" listesini çekiyoruz
      if (data.containsKey('chunks')) {
        _chunks = List<Map<String, dynamic>>.from(data['chunks']);
        debugPrint(
          "✅ Bilgi bankası yüklendi. Toplam chunk sayısı: ${_chunks.length}",
        );
      } else {
        debugPrint("⚠️ JSON içinde 'chunks' anahtarı bulunamadı!");
      }
    } catch (e) {
      debugPrint("❌ Bilgi bankası yüklenirken hata oluştu: $e");
    }
  }

  // Token-based skorlama: query'deki her anlamlı kelime için chunk'ın text,
  // title ve category alanlarında geçen kelime sayısını sayar. Title eşleşmesi
  // 3x, category 2x, text 1x ağırlığa sahip. En yüksek skorlu chunk döndürülür.
  Map<String, dynamic>? bestChunk(String query) {
    if (_chunks.isEmpty) return null;

    final tokens = _tokenize(query);
    if (tokens.isEmpty) return null;

    Map<String, dynamic>? best;
    var bestScore = 0;

    for (final chunk in _chunks) {
      final text = chunk['text']?.toString().toLowerCase() ?? '';
      final title = chunk['title']?.toString().toLowerCase() ?? '';
      final category = chunk['category']?.toString().toLowerCase() ?? '';

      var score = 0;
      for (final token in tokens) {
        if (title.contains(token)) score += 3;
        if (category.contains(token)) score += 2;
        if (text.contains(token)) score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        best = chunk;
      }
    }

    return bestScore > 0 ? best : null;
  }

  String searchRelevantInfo(String query) {
    final chunk = bestChunk(query);
    return chunk?['text']?.toString() ?? '';
  }

  Future<String> getRelevantContext(String query) async {
    return searchRelevantInfo(query);
  }

  static const _stopWords = <String>{
    've', 'ile', 'için', 'bir', 'bu', 'şu', 'da', 'de', 'mi', 'mu', 'mü',
    'ne', 'nasıl', 'nerede', 'nedir', 'kim', 'kime', 'neden',
    'var', 'yok', 'beni', 'sana', 'bana', 'olan', 'olur',
  };

  List<String> _tokenize(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\wçğıöşüâîû\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 3 && !_stopWords.contains(t))
        .toList();
  }
}
