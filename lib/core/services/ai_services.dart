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
  bool _gemmaTried = false;

  AIService(this._knowledgeService);

  bool get isGemmaReady => _chat != null;

  /// Gemma modelini bir kez başlatmayı dener. Cihazda model yüklü değilse
  /// sessizce başarısız olur — bu durumda bilgi bankası fallback'i kullanılır.
  Future<void> initModel() async {
    if (_gemmaTried) return;
    _gemmaTried = true;
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.gpu,
      );
      _chat = await _model!.createChat();
      debugPrint('✅ Yerel Gemma modeli hazır.');
    } catch (e) {
      debugPrint('ℹ️ Gemma modeli yok, bilgi bankası fallback kullanılacak: $e');
      _model = null;
      _chat = null;
    }
  }

  Future<String> answerQuestion(String userQuery) async {
    if (!_gemmaTried) await initModel();

    final chunk = _knowledgeService.bestChunk(userQuery);

    if (isGemmaReady) {
      final answer = await _askGemma(userQuery, chunk?['text']?.toString());
      if (answer != null && answer.trim().isNotEmpty) return answer;
    }

    return _knowledgeFallback(userQuery, chunk);
  }

  Future<String?> _askGemma(String userQuery, String? context) async {
    try {
      final prompt = context != null && context.isNotEmpty
          ? '''
Sen 'Yanında' isimli çevrimdışı deprem ve acil durum asistanısın.
Yalnızca aşağıdaki güvenilir bilgileri kullanarak kısa, net ve sakinleştirici bir cevap ver.
Asla bu bilgilerin dışına çıkma ve hayali bilgi uydurma.

[GÜVENİLİR BİLGİ]:
$context

[KULLANICI SORUSU]:
$userQuery
'''
          : '''
Sen 'Yanında' isimli acil durum asistanısın.
Kullanıcıya deprem, ilk yardım veya hayatta kalma konularında kısa, net ve panik yaptırmayacak bir cevap ver.

[KULLANICI SORUSU]:
$userQuery
''';

      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));
      final result = await _chat!.generateChatResponse();
      final text = (result as dynamic).text as String? ??
          (result as dynamic).token as String? ??
          result.toString();
      return text;
    } catch (e) {
      debugPrint('⚠️ Gemma yanıt üretemedi, fallback kullanılıyor: $e');
      return null;
    }
  }

  /// Bilgi bankasından gelen chunk'ı kullanıcı dostu kısa bir yanıta dönüştürür.
  /// Hackathon demosu için Gemma indirilmemiş olsa da kullanışlı cevaplar verir.
  String _knowledgeFallback(String userQuery, Map<String, dynamic>? chunk) {
    if (chunk == null) {
      return 'Bu konuda elimde güvenilir bilgi yok. '
          'Acil bir durumdaysan 112\'yi ara veya ana ekrandan SOS butonuna bas.';
    }

    final title = chunk['title']?.toString().trim();
    final text = chunk['text']?.toString().trim() ?? '';
    final shortened = _shorten(text, maxChars: 600);

    if (title != null && title.isNotEmpty) {
      return '$title\n\n$shortened';
    }
    return shortened;
  }

  String _shorten(String text, {required int maxChars}) {
    if (text.length <= maxChars) return text;
    // Cümle sınırında kesmeye çalış.
    final slice = text.substring(0, maxChars);
    final lastStop = slice.lastIndexOf(RegExp(r'[\.\!\?]'));
    if (lastStop > maxChars ~/ 2) {
      return '${slice.substring(0, lastStop + 1)}…';
    }
    return '$slice…';
  }
}
