//Bu kod ile birlikte "Lokal AI ve RAG Hazırlığı"
// mimari olarak tamamen bitmiş oluyor! 
//Artık yapay zeka hem çevrimdışı çalışacak hem de ürettiğimiz yanıtları 
//.json dosyasındaki bilgilerle zenginleştirecek.


import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// RAG motorumuzu import ediyoruz (dosya yollarının projene uygun olduğundan emin ol)
import 'knowledge_service.dart';

// Riverpod Provider'ımızı KnowledgeService'i de alacak şekilde güncelliyoruz
final aiServiceProvider = Provider<AIService>((ref) {
  final knowledgeService = ref.read(knowledgeServiceProvider);
  return AIService(knowledgeService);
});

class AIService {
  final KnowledgeService _knowledgeService;

  InferenceModel? _model;
  InferenceChat? _chat;

  bool get isReady => _model != null && _chat != null;

  // Constructor ile knowledge servisimizi içeri aldık
  AIService(this._knowledgeService);

  Future<void> init() async {
    if (isReady) return;

    try {
      debugPrint("Gemma AI başlatılıyor...");

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await _model!.createChat();

      debugPrint("Gemma AI başarıyla yüklendi ve hazır!");
    } catch (e) {
      debugPrint("Gemma AI başlatılırken kritik hata: $e");
    }
  }

  /// RAG Entegreli Ana Sohbet Fonksiyonu
  Future<String> generateResponse(String prompt) async {
    if (!isReady) {
      return "Sistem uyarısı: Yapay zeka henüz tam yüklenmedi, lütfen bekleyin.";
    }

    try {
      // 1. ADIM: Kullanıcının sorusuna en uygun bilgileri knowledge_service'ten çek
      final contextTexts = await _knowledgeService.getRelevantContext(prompt);

      // 2. ADIM: Gemma'ya verilecek asıl System Prompt'unu hazırla
      String finalPrompt = prompt;

      if (contextTexts.isNotEmpty) {
        // Eğer json'dan eşleşen bir bilgi bulduysak, Gemma'yı sadece bu bilgiyi kullanmaya zorluyoruz
        finalPrompt =
            '''
Aşağıdaki güvenilir AFAD ve Kızılay bilgilerini kullanarak kullanıcının sorusuna sade, kısa ve sakin bir dille Türkçe cevap ver. Eğer sorunun cevabı bu bilgilerde yoksa "Bu konuda kesin bir bilgim yok, lütfen acil durum yetkililerine danışın" de. Asla uydurma yapma.

BİLGİLER:
$contextTexts

KULLANICI SORUSU: $prompt

CEVAP:''';
      }

      // 3. ADIM: Zenginleştirilmiş prompt'u modele gönder
      await _chat!.addQueryChunk(Message.text(text: finalPrompt, isUser: true));

      // Yeni API ile yanıt objesini alıyoruz
      final result = await _chat!.generateChatResponse();

      final responseText =
          (result as dynamic).text ??
          (result as dynamic).token ??
          result.toString();

      return responseText;
    } catch (e) {
      debugPrint("Yanıt üretme hatası: $e");
      return "Şu an yanıt veremiyorum, lütfen tekrar deneyin.";
    }
  }
}
