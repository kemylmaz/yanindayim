// Bu servis, yerel Gemma modelini yönetir ve kullanıcının sorularını
// bilgi bankasından (RAG) gelen bağlam verileriyle birleştirerek cevap üretir.

//flutterGemma.getActiveModel üzerinden InferenceModel ve InferenceChat
//nesnelerini yakalayıp, GPU tercihini belirterek
// addQueryChunk ve generateChatResponse akışını kurduk

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'knowledge_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final knowledgeService = ref.watch(knowledgeServiceProvider);
  return AIService(knowledgeService);
});

class AIService {
  final KnowledgeService _knowledgeService;
  InferenceModel? _model;
  InferenceChat? _chat;

  AIService(this._knowledgeService);

  // Modeli güvenli bir şekilde başlatan fonksiyon (Kullanılmayan değişken hatası çözüldü)
  Future<void> initModel() async {
    try {
      if (_model == null) {
        // Modeli sadece hafızaya yükleyerek hazır hale getiriyoruz
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 512,
          preferredBackend: PreferredBackend.gpu,
        );
        _chat = await _model!.createChat();
        debugPrint("✅ Yerel Gemma Modeli başarıyla hazırlandı.");
      }
    } catch (e) {
      debugPrint("❌ Yerel Gemma Modeli başlatılırken hata: $e");
    }
  }

  // Cihaz içi LLM'den yanıt alan ana fonksiyon (getAnswer tanım hatası çözüldü)
  Future<String> answerQuestion(String userQuery) async {
    try {
      // 1. Adım: Bilgi bankasından ilgili bağlamı sorgula
      final String context = await _knowledgeService.getRelevantContext(
        userQuery,
      );

      String finalPrompt = "";

      // 2. Adım: Prompt yapısını RAG formatına göre hazırla
      if (context.isNotEmpty) {
        finalPrompt =
            """
Sen 'Yanında' isimli çevrimdışı deprem ve acil durum asistanısın. 
Yalnızca sana verilen aşağıdaki güvenilir bilgileri kullanarak kısa, net ve sakinleştirici bir cevap ver. 
Asla bu bilgilerin dışına çıkma ve hayali bilgi uydurma.

[GÜVENİLİR BİLGİ]:
$context

[KULLANICI SORUSU]:
$userQuery
""";
      } else {
        finalPrompt =
            """
Sen 'Yanında' isimli acil durum asistanısın. 
Kullanıcıya deprem, ilk yardım veya hayatta kalma konularında kısa, net ve panik yaptırmayacak bir cevap ver.

[KULLANICI SORUSU]:
$userQuery
""";
      }

      // 3. Adım: Güncel flutter_gemma paket standartlarına göre cevabı iste
      if (_model == null || _chat == null) {
        await initModel();
      }

      if (_chat != null) {
        await _chat!.addQueryChunk(
          Message.text(text: finalPrompt, isUser: true),
        );
        final result = await _chat!.generateChatResponse();
        final responseText =
            (result as dynamic).text ??
            (result as dynamic).token ??
            result.toString();
        return responseText;
      }

      return "Şu an yanıt üretemiyorum, lütfen tekrar dener misin?";
    } catch (e) {
      debugPrint("❌ Yanıt üretilirken hata oluştu: $e");
      return "Acil durum hattı şu an yanıt veremiyor. Lütfen sakin kalın.";
    }
  }
}
