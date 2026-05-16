import 'package:flutter/foundation.dart'; // debugPrint için
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  InferenceModel? _model;
  InferenceChat? _chat; // InferenceModelSession yerine InferenceChat yazıyoruz

  bool get isReady => _model != null && _chat != null;
  // ... (kodun geri kalanı aynı)

  /// Gemma'yı cihazda ilk kez ayağa kaldıran fonksiyon
  Future<void> init() async {
    if (isReady) return;

    try {
      debugPrint("Gemma AI başlatılıyor...");

      // flutter_gemma 0.15.1 API'sine uygun model yükleme
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend:
            PreferredBackend.gpu, // Cihazın NPU/GPU gücünü kullanması için
      );

      _chat = await _model!.createChat();

      debugPrint("Gemma AI başarıyla yüklendi ve hazır!");
    } catch (e) {
      debugPrint("Gemma AI başlatılırken kritik hata: $e");
    }
  }

  /// RAG sistemi ile birleştireceğimiz ana sohbet fonksiyonu
  /// RAG sistemi ile birleştireceğimiz ana sohbet fonksiyonu
  Future<String> generateResponse(String prompt) async {
    if (!isReady) {
      return "Sistem uyarısı: Yapay zeka henüz tam yüklenmedi, lütfen bekleyin.";
    }

    try {
      // Mesajı modele iletiyoruz
      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));

      // Yeni API ile yanıt objesini alıyoruz
      final result = await _chat!.generateChatResponse();

      // flutter_gemma'nın yeni versiyonunda TextResponse objesinden metni güvenle çıkarıyoruz
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
