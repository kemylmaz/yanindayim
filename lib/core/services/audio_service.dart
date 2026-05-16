import 'package:audioplayers/audioplayers.dart';

/// Düdük çalma servisi. Singleton, app boyunca tek instance.
/// Asset'ten 3 kHz aralıklı WAV dosyasını sürekli loop'ta çalar.
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playWhistle() async {
    if (_isPlaying) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.play(AssetSource('audio/whistle_3khz.wav'));
    _isPlaying = true;
  }

  Future<void> stopWhistle() async {
    await _player.stop();
    _isPlaying = false;
  }
}
