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

  // Kullanıcının yazdığı mesajla bilgi bankasındaki metinleri eşleştirme
  String searchRelevantInfo(String query) {
    if (_chunks.isEmpty) return "";

    final lowerQuery = query.toLowerCase();

    // Kelime kelime eşleşme kontrolü (Arama kalitesini artırmak için)
    for (var chunk in _chunks) {
      final text = chunk['text']?.toString().toLowerCase() ?? '';
      final title = chunk['title']?.toString().toLowerCase() ?? '';
      final category = chunk['category']?.toString().toLowerCase() ?? '';

      // Eğer sorunun içinde başlık, kategori veya metnin kendisi geçiyorsa
      if (text.contains(lowerQuery) ||
          title.contains(lowerQuery) ||
          category.contains(lowerQuery)) {
        // Yapay zekaya doğrudan ham metni (text) paslayacağız
        return chunk['text'].toString();
      }
    }

    return ""; // Eşleşen bir şey bulamazsa boş dön
  }

  Future<String> getRelevantContext(String query) async {
    return searchRelevantInfo(query);
  }
}
