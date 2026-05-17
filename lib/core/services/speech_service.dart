// Mikrofonu dinleyip sözleri metne çevirir. Türkçe odaklı, kalıcı dinleme.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  bool get isListening => _speech.isListening;

  /// Cihazda STT motoru var mı kontrol eder + mikrofon iznini ister.
  Future<bool> initSpeech() async {
    if (_isAvailable) return true;

    // 1) Mikrofon iznini iste (Android'de runtime izin).
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('⚠️ Mikrofon izni reddedildi.');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ İzin isteği hata verdi: $e');
    }

    // 2) STT motorunu başlat.
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (s) => debugPrint('🎙️ STT durumu: $s'),
        onError: (e) => debugPrint('❌ STT hata: ${e.errorMsg}'),
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('❌ STT init başarısız: $e');
      _isAvailable = false;
      return false;
    }
  }

  /// Dinlemeyi başlatır. [onResult] kısmi sonuçlarla sürekli tetiklenir.
  /// 30 sn'lik kalıcı pencere; konuşma duraklarsa otomatik tekrar başlar.
  Future<void> startListening({required Function(String) onResult}) async {
    final ready = await initSpeech();
    if (!ready) return;

    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
      localeId: 'tr_TR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) await _speech.stop();
  }
}
