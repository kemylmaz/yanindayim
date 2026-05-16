import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Erişilebilirlik servisi — işitme ve görme engelli kullanıcılara destek.
///
/// İŞİTME ENGELLİ: SOS sırasında telefon güçlü ve sürekli titrer.
///   Flutter'ın HapticFeedback API'si periyodik Timer ile sürekli darbeye
///   dönüştürülür (gerçek vibration motoru kullanır).
///
/// GÖRME ENGELLİ: Mikrofon dinlenir; "durdur" / "kapat" / "tamam" kelimeleri
///   tanındığında düdük durdurulur. Offline çalışır (Android/iOS'un yerleşik
///   ASR motorlarını kullanır — dil paketi cihazda yüklüyse).
class AccessibilityService {
  AccessibilityService._();
  static final instance = AccessibilityService._();

  final SpeechToText _speech = SpeechToText();
  Timer? _vibrationTimer;
  bool _vibrationActive = false;
  bool _speechInitialized = false;
  bool _listening = false;

  bool get isVibrating => _vibrationActive;
  bool get isListening => _listening;

  // ──────────────────────── titreşim (işitme engelli) ────────────────────────

  /// SOS aktifken sürekli güçlü titreşim başlatır.
  /// 500ms aralıklarla heavy impact darbesi gönderir.
  void startSosVibration() {
    if (_vibrationActive) return;
    _vibrationActive = true;
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  void stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _vibrationActive = false;
  }

  // ─────────────────────── sesli komut (görme engelli) ───────────────────────

  /// Cihazda Türkçe ASR var mı kontrol eder.
  Future<bool> initializeSpeech() async {
    if (_speechInitialized) return true;
    try {
      _speechInitialized = await _speech.initialize(
        onError: (error) =>
            debugPrint('Speech recognition error: ${error.errorMsg}'),
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _speechInitialized = false;
    }
    return _speechInitialized;
  }

  /// Sesli komut dinlemeyi başlatır.
  /// Tanınan kelime [stopKeywords] içindeyse [onStopRecognized] tetiklenir.
  Future<void> startListening({
    required VoidCallback onStopRecognized,
  }) async {
    if (_listening) return;
    final ready = await initializeSpeech();
    if (!ready) return;

    _listening = true;

    void restart() {
      if (!_listening) return;
      _speech.listen(
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        localeId: 'tr_TR',
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          if (_matchesStopCommand(words)) {
            onStopRecognized();
            stopListening();
          }
        },
      );
    }

    _speech.statusListener = (status) {
      // Süre dolduğunda otomatik yeniden başlat (uzun dinleme için).
      if (status == 'notListening' && _listening) {
        Future.delayed(const Duration(milliseconds: 300), restart);
      }
    };

    restart();
  }

  Future<void> stopListening() async {
    _listening = false;
    _speech.statusListener = null;
    await _speech.stop();
  }

  /// "durdur", "kapat", "tamam", "yeter" gibi durdurma niyetini yakalar.
  bool _matchesStopCommand(String words) {
    const stopKeywords = [
      'durdur',
      'kapat',
      'tamam',
      'yeter',
      'sustur',
      'stop',
    ];
    return stopKeywords.any(words.contains);
  }

  // ───────────────────────────── temizlik ────────────────────────────────────

  void dispose() {
    stopVibration();
    stopListening();
  }
}
