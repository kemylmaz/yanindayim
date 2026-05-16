// Bu servis, cihazın mikrofonunu kullanarak kullanıcının sesli komutlarını
// dinler ve bu ses kayıtlarını gerçek zamanlı olarak metne (String) çevirir.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  // Servisi ilk kez hazır hale getirmek ve kullanıcıdan mikrofon izni istemek için fonksiyon
  Future<bool> initSpeech() async {
    if (_isAvailable) return true;

    try {
      // Cihazın ses tanıma motorunu başlatıyoruz
      _isAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('🎙️ Ses Durumu: $status'),
        onError: (errorNotification) =>
            debugPrint('❌ Ses Hatası: $errorNotification'),
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('❌ SpeechToText başlatılamadı: $e');
      return false;
    }
  }

  // Dinlemeyi başlatan fonksiyon. Gelen sesleri anlık olarak kelime kelime 'onResult' callback'ine fırlatır.
  Future<void> startListening({required Function(String) onResult}) async {
    bool ready = await initSpeech();
    if (!ready) {
      debugPrint('⚠️ Mikrofon izni reddedildi veya cihaz desteklemiyor.');
      return;
    }

    await _speech.listen(
      onResult: (result) {
        // Kullanıcı konuşmayı bitirdikçe veya durakladıkça en net metni yakalayıp ekrana paslıyoruz
        if (result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      localeId:
          'tr_TR', // Hackathon Türkiye'de olduğu için Türkçe dil paketini zorunlu kılıyoruz
      listenFor: const Duration(seconds: 20), // Maksimum dinleme süresi
      pauseFor: const Duration(
        seconds: 3,
      ), // Kullanıcı 3 saniye susarsa dinlemeyi otomatik bitir
    );
  }

  // Dinlemeyi manuel olarak durdurmak için fonksiyon
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  // Şu an aktif olarak dinleme yapılıyor mu bilgisini dönen getter
  bool get isListening => _speech.isListening;
}
