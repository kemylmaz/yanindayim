import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android tarafına `com.appjam.yaninda/lockscreen` method channel ile
/// `showOverLockscreen` / `hideOverLockscreen` çağrıları yapar.
///
/// SOS aktifken kilit ekranı bypass edilir — kullanıcı telefonu uyandırınca
/// doğrudan SOS aktif ekranını (sağlık kart özetiyle) görür, kilit açmaya
/// gerek yoktur.
class LockscreenService {
  LockscreenService._();
  static final instance = LockscreenService._();

  static const _channel = MethodChannel('com.appjam.yaninda/lockscreen');

  Future<void> showOverLockscreen() async {
    try {
      await _channel.invokeMethod('showOverLockscreen');
    } on PlatformException catch (e) {
      debugPrint('⚠️ Lockscreen show hata: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ Lockscreen channel hata: $e');
    }
  }

  Future<void> hideOverLockscreen() async {
    try {
      await _channel.invokeMethod('hideOverLockscreen');
    } on PlatformException catch (e) {
      debugPrint('⚠️ Lockscreen hide hata: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ Lockscreen channel hata: $e');
    }
  }
}
